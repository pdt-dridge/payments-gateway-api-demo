# Troubleshooting Guide - Payments Gateway API

## Common Issues

### 1. Payment Failures

#### Symptoms
- Payments returning `payment_failed` error
- High failure rate
- Customer complaints

#### Diagnostic Steps

**Check Payment Provider Status:**
```bash
# Check Stripe status
curl https://status.stripe.com/api/v2/status.json

# Check PayPal status
curl https://www.paypal-status.com/api/v2/status.json
```

**Check Recent Errors:**
```bash
kubectl logs -n payments -l app=gateway --since=30m | grep "payment_failed"
```

**Check Metrics:**
```bash
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep payment_success_rate
```

#### Common Causes

1. **Invalid API Keys**
   - Check API key expiration
   - Verify API key permissions
   - Rotate keys if needed

2. **Rate Limiting**
   - Check rate limit headers
   - Implement backoff strategy
   - Contact provider to increase limits

3. **Insufficient Funds**
   - Customer issue, not system issue
   - Provide clear error message

4. **Card Declined**
   - Customer issue
   - Suggest alternative payment method

#### Resolution

```bash
# Rotate API keys
cd scripts
./rotate-api-keys.sh stripe

# Check configuration
kubectl get configmap/gateway-config -n payments -o yaml

# Restart service
kubectl rollout restart deployment/gateway -n payments
```

### 2. High Latency

#### Symptoms
- API response time > 2s
- Timeout errors
- Slow customer experience

#### Diagnostic Steps

**Check Current Latency:**
```bash
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep http_request_duration
```

**Check Database Performance:**
```bash
# Check slow queries
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
```

**Check External API Latency:**
```bash
kubectl logs -n payments -l app=gateway --since=15m | grep "provider_latency"
```

#### Common Causes

1. **Database Slow Queries**
   - Missing indexes
   - Inefficient queries
   - High load

2. **External API Timeouts**
   - Provider issues
   - Network latency
   - Timeout too short

3. **Resource Constraints**
   - High CPU usage
   - Memory pressure
   - Pod throttling

4. **Cache Miss Rate**
   - Cache not warmed up
   - Cache eviction
   - Cache unavailable

#### Resolution

**Scale Resources:**
```bash
# Horizontal scaling
kubectl scale deployment/gateway -n payments --replicas=10

# Check autoscaling
kubectl get hpa -n payments
```

**Optimize Database:**
```bash
# Add index
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "CREATE INDEX CONCURRENTLY idx_payments_customer_id ON payments(customer_id);"
```

**Increase Timeouts:**
```bash
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"PAYMENT_TIMEOUT":"30s"}}'
kubectl rollout restart deployment/gateway -n payments
```

### 3. Database Connection Issues

#### Symptoms
- "Connection pool exhausted" errors
- "Too many connections" errors
- Database timeouts

#### Diagnostic Steps

**Check Connection Pool:**
```bash
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep db_pool
```

**Check Database Connections:**
```bash
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

#### Common Causes

1. **Connection Pool Too Small**
   - Increase pool size
   - Optimize connection usage

2. **Connection Leaks**
   - Connections not being released
   - Application bug

3. **Database Overload**
   - Too many queries
   - Slow queries blocking connections

#### Resolution

**Increase Pool Size:**
```bash
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"DB_POOL_SIZE":"100"}}'
kubectl rollout restart deployment/gateway -n payments
```

**Kill Long-Running Queries:**
```bash
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '5 minutes';"
```

### 4. Authentication Failures

#### Symptoms
- 401 Unauthorized errors
- "Invalid API key" messages
- Authentication errors in logs

#### Diagnostic Steps

**Check API Key:**
```bash
# Verify API key exists
kubectl get secret -n payments stripe-api-key

# Check API key format
kubectl get secret -n payments stripe-api-key -o jsonpath='{.data.key}' | base64 -d
```

**Check Logs:**
```bash
kubectl logs -n payments -l app=gateway --since=30m | grep "authentication_failed"
```

#### Common Causes

1. **Expired API Key**
   - Rotate API key
   - Update secret

2. **Wrong API Key**
   - Using test key in production
   - Using old key

3. **Permissions Issue**
   - API key lacks required permissions
   - Contact provider

#### Resolution

**Rotate API Key:**
```bash
cd scripts
./rotate-api-keys.sh stripe
```

**Update Secret:**
```bash
kubectl create secret generic stripe-api-key   --from-literal=key=sk_live_new_key   --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/gateway -n payments
```

### 5. Webhook Delivery Failures

#### Symptoms
- Webhooks not being received
- Payment status not updating
- Webhook errors in logs

#### Diagnostic Steps

**Check Webhook Logs:**
```bash
kubectl logs -n payments -l app=gateway --since=1h | grep "webhook"
```

**Check Webhook Configuration:**
```bash
# Check Stripe webhooks
curl https://api.stripe.com/v1/webhook_endpoints   -u sk_live_YOUR_KEY:

# Check PayPal webhooks
# (Use PayPal dashboard)
```

#### Common Causes

1. **Webhook URL Incorrect**
   - Update webhook URL in provider dashboard

2. **Webhook Secret Mismatch**
   - Verify webhook secret
   - Update secret if needed

3. **Firewall/Network Issue**
   - Check network policies
   - Verify ingress configuration

#### Resolution

**Update Webhook Secret:**
```bash
kubectl create secret generic stripe-webhook-secret   --from-literal=secret=whsec_new_secret   --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/gateway -n payments
```

## Debugging Tools

### Logs
```bash
# Real-time logs
kubectl logs -n payments -l app=gateway -f

# Logs from specific pod
kubectl logs -n payments <pod-name>

# Logs from previous pod (if crashed)
kubectl logs -n payments <pod-name> --previous
```

### Metrics
```bash
# Prometheus metrics
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics

# Pod metrics
kubectl top pods -n payments

# Node metrics
kubectl top nodes
```

### Database
```bash
# Connect to database
kubectl exec -it -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments

# Check active queries
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active' 
ORDER BY duration DESC;

# Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Cache
```bash
# Connect to Redis
kubectl exec -it -n payments deploy/gateway -- redis-cli -h payments-cache.prod.internal

# Check cache stats
INFO stats

# Check memory usage
INFO memory

# Check keys
KEYS payment:*
```

## Performance Optimization

### Database Optimization
- Add indexes for frequently queried columns
- Use EXPLAIN ANALYZE for slow queries
- Implement connection pooling
- Use read replicas for read-heavy operations

### Caching Strategy
- Cache frequently accessed data
- Set appropriate TTLs
- Implement cache warming
- Monitor cache hit rate

### API Optimization
- Implement request batching
- Use pagination for large result sets
- Compress responses
- Implement rate limiting

## Monitoring Checklist

- [ ] Payment success rate > 99%
- [ ] API latency p95 < 1s
- [ ] Error rate < 1%
- [ ] Database connection pool < 80%
- [ ] Cache hit rate > 80%
- [ ] CPU utilization < 70%
- [ ] Memory utilization < 80%
- [ ] No pod restarts in last hour

## Escalation

If issue persists after troubleshooting:

1. **Check runbooks** for specific incident types
2. **Escalate to team lead** if not resolved in 15 minutes
3. **Page on-call engineer** for critical issues
4. **Contact vendor support** for provider-specific issues

## Related Resources

- [Architecture Documentation](architecture.md)
- [API Endpoints](api-endpoints.md)
- [Payment Failure Runbook](../runbooks/payment-failure-runbook.md)
- [High Latency Runbook](../runbooks/high-latency-runbook.md)
