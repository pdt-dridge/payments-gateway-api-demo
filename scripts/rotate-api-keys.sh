#!/bin/bash
# API Key Rotation Script
# Usage: ./rotate-api-keys.sh <provider>

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;m'

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <provider>"
    echo "Providers: stripe, paypal, all"
    exit 1
fi

PROVIDER=$1
NAMESPACE="payments"
DEPLOYMENT="gateway"

echo "========================================="
echo "API Key Rotation"
echo "========================================="
echo "Provider: $PROVIDER"
echo ""

rotate_stripe() {
    echo "Rotating Stripe API key..."

    # Backup current key
    echo "1. Backing up current key..."
    kubectl get secret stripe-api-key -n $NAMESPACE -o yaml > stripe-api-key-backup-$(date +%Y%m%d-%H%M%S).yaml
    echo -e "${GREEN}✓ Backup created${NC}"

    # Prompt for new key
    echo ""
    echo "2. Enter new Stripe API key:"
    read -s NEW_KEY

    # Update secret
    echo ""
    echo "3. Updating secret..."
    kubectl create secret generic stripe-api-key \
        --from-literal=key=$NEW_KEY \
        --dry-run=client -o yaml | kubectl apply -f - -n $NAMESPACE
    echo -e "${GREEN}✓ Secret updated${NC}"

    # Restart deployment
    echo ""
    echo "4. Restarting deployment..."
    kubectl rollout restart deployment/$DEPLOYMENT -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    echo -e "${GREEN}✓ Deployment restarted${NC}"

    # Verify
    echo ""
    echo "5. Verifying..."
    sleep 10
    HEALTH=$(kubectl exec -n $NAMESPACE deploy/$DEPLOYMENT -- curl -s localhost:8080/health | jq -r '.checks.stripe')
    if [ "$HEALTH" == "healthy" ]; then
        echo -e "${GREEN}✓ Stripe connection verified${NC}"
    else
        echo -e "${RED}✗ Stripe connection failed${NC}"
        echo "Please check logs and consider rolling back!"
        exit 1
    fi
}

rotate_paypal() {
    echo "Rotating PayPal API credentials..."

    # Backup current credentials
    echo "1. Backing up current credentials..."
    kubectl get secret paypal-credentials -n $NAMESPACE -o yaml > paypal-credentials-backup-$(date +%Y%m%d-%H%M%S).yaml
    echo -e "${GREEN}✓ Backup created${NC}"

    # Prompt for new credentials
    echo ""
    echo "2. Enter new PayPal Client ID:"
    read -s CLIENT_ID
    echo "   Enter new PayPal Client Secret:"
    read -s CLIENT_SECRET

    # Update secret
    echo ""
    echo "3. Updating secret..."
    kubectl create secret generic paypal-credentials \
        --from-literal=client_id=$CLIENT_ID \
        --from-literal=client_secret=$CLIENT_SECRET \
        --dry-run=client -o yaml | kubectl apply -f - -n $NAMESPACE
    echo -e "${GREEN}✓ Secret updated${NC}"

    # Restart deployment
    echo ""
    echo "4. Restarting deployment..."
    kubectl rollout restart deployment/$DEPLOYMENT -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    echo -e "${GREEN}✓ Deployment restarted${NC}"

    # Verify
    echo ""
    echo "5. Verifying..."
    sleep 10
    HEALTH=$(kubectl exec -n $NAMESPACE deploy/$DEPLOYMENT -- curl -s localhost:8080/health | jq -r '.checks.paypal')
    if [ "$HEALTH" == "healthy" ]; then
        echo -e "${GREEN}✓ PayPal connection verified${NC}"
    else
        echo -e "${RED}✗ PayPal connection failed${NC}"
        echo "Please check logs and consider rolling back!"
        exit 1
    fi
}

# Execute rotation
case $PROVIDER in
    stripe)
        rotate_stripe
        ;;
    paypal)
        rotate_paypal
        ;;
    all)
        rotate_stripe
        echo ""
        rotate_paypal
        ;;
    *)
        echo "Unknown provider: $PROVIDER"
        echo "Supported providers: stripe, paypal, all"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "API Key Rotation Complete"
echo "========================================="
