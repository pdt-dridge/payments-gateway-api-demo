#!/bin/bash
# Rollback Deployment Script
# Usage: ./rollback-deployment.sh <namespace> <deployment> [revision]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;m'

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <namespace> <deployment> [revision]"
    echo "Example: $0 payments gateway"
    echo "Example: $0 payments gateway 5"
    exit 1
fi

NAMESPACE=$1
DEPLOYMENT=$2
REVISION=$3

echo "========================================="
echo "Deployment Rollback"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "Deployment: $DEPLOYMENT"
echo ""

# Show deployment history
echo "Deployment History:"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE
echo ""

# Confirm rollback
if [ -z "$REVISION" ]; then
    echo -e "${YELLOW}This will rollback to the previous revision.${NC}"
else
    echo -e "${YELLOW}This will rollback to revision $REVISION.${NC}"
fi

read -p "Are you sure you want to proceed? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "Starting rollback..."

# Perform rollback
if [ -z "$REVISION" ]; then
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
else
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --to-revision=$REVISION
fi

echo ""
echo "Waiting for rollback to complete..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

echo ""
echo -e "${GREEN}✓ Rollback completed successfully${NC}"

# Show current image
echo ""
echo "Current deployment image:"
kubectl get deployment/$DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# Run health check
echo ""
echo "Running post-rollback health check..."
sleep 5

HEALTH_CHECK=$(kubectl exec -n $NAMESPACE deploy/$DEPLOYMENT -- curl -s -f localhost:8080/health || echo "FAILED")
if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    echo "Please investigate immediately!"
    exit 1
fi

echo ""
echo "========================================="
echo "Rollback Complete"
echo "========================================="
