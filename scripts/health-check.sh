#!/bin/bash
# Health Check Script for Payments Gateway API
# Usage: ./health-check.sh

set -e

echo "========================================="
echo "Payments Gateway API - Health Check"
echo "========================================="
echo ""

# Configuration
NAMESPACE="payments"
DEPLOYMENT="gateway"
API_URL="https://api.payments.example.com"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;m' # No Color

# Check API Health
echo "1. Checking API Health..."
if curl -s -f "${API_URL}/health" > /dev/null; then
    echo -e "${GREEN}✓ API is healthy${NC}"
    curl -s "${API_URL}/health" | jq '.'
else
    echo -e "${RED}✗ API health check failed${NC}"
    exit 1
fi
echo ""

# Check Database Connectivity
echo "2. Checking Database Connectivity..."
DB_CHECK=$(kubectl exec -n ${NAMESPACE} deploy/${DEPLOYMENT} -- psql -h payments-db.prod.internal -U payments -c "SELECT 1;" 2>&1)
if echo "$DB_CHECK" | grep -q "1 row"; then
    echo -e "${GREEN}✓ Database is accessible${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    echo "$DB_CHECK"
    exit 1
fi
echo ""

# Check Cache Connectivity
echo "3. Checking Cache Connectivity..."
CACHE_CHECK=$(kubectl exec -n ${NAMESPACE} deploy/${DEPLOYMENT} -- redis-cli -h payments-cache.prod.internal PING 2>&1)
if echo "$CACHE_CHECK" | grep -q "PONG"; then
    echo -e "${GREEN}✓ Cache is accessible${NC}"
else
    echo -e "${RED}✗ Cache connection failed${NC}"
    echo "$CACHE_CHECK"
    exit 1
fi
echo ""

# Check Payment Provider Status
echo "4. Checking Payment Provider Status..."
echo "   Stripe:"
STRIPE_STATUS=$(curl -s https://status.stripe.com/api/v2/status.json | jq -r '.status.indicator')
if [ "$STRIPE_STATUS" == "none" ]; then
    echo -e "   ${GREEN}✓ Stripe is operational${NC}"
else
    echo -e "   ${YELLOW}⚠ Stripe status: $STRIPE_STATUS${NC}"
fi

echo "   PayPal:"
echo -e "   ${YELLOW}⚠ Check manually: https://www.paypal-status.com${NC}"
echo ""

# Check API Response Time
echo "5. Checking API Response Time..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "${API_URL}/health")
RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc)
echo "   Response time: ${RESPONSE_MS}ms"
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    echo -e "   ${GREEN}✓ Response time is good${NC}"
else
    echo -e "   ${YELLOW}⚠ Response time is slow${NC}"
fi
echo ""

# Check Metrics Endpoint
echo "6. Checking Metrics Endpoint..."
if kubectl exec -n ${NAMESPACE} deploy/${DEPLOYMENT} -- curl -s -f localhost:8080/metrics > /dev/null; then
    echo -e "${GREEN}✓ Metrics endpoint is accessible${NC}"

    # Get key metrics
    echo ""
    echo "   Key Metrics:"
    kubectl exec -n ${NAMESPACE} deploy/${DEPLOYMENT} -- curl -s localhost:8080/metrics | grep -E "payment_success_rate|http_request_duration_seconds" | head -5
else
    echo -e "${RED}✗ Metrics endpoint failed${NC}"
fi
echo ""

# Check Pod Status
echo "7. Checking Pod Status..."
PODS=$(kubectl get pods -n ${NAMESPACE} -l app=${DEPLOYMENT} --no-headers)
TOTAL_PODS=$(echo "$PODS" | wc -l)
RUNNING_PODS=$(echo "$PODS" | grep -c "Running" || true)
echo "   Total pods: $TOTAL_PODS"
echo "   Running pods: $RUNNING_PODS"
if [ "$TOTAL_PODS" -eq "$RUNNING_PODS" ]; then
    echo -e "   ${GREEN}✓ All pods are running${NC}"
else
    echo -e "   ${RED}✗ Some pods are not running${NC}"
    kubectl get pods -n ${NAMESPACE} -l app=${DEPLOYMENT}
fi
echo ""

echo "========================================="
echo "Health Check Complete"
echo "========================================="
