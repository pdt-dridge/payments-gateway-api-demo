# High Latency Incident Runbook

## Severity: Medium to High
**Last Updated:** 2026-03-19  
**Owner:** Platform Team  
**Slack Channel:** #incidents-performance

## Symptoms
- API response time p95 > 2000ms
- API response time p99 > 5000ms
- Customer complaints about slow payments
- PagerDuty alert: "High API Latency"

## Initial Response (First 5 minutes)

### 1. Acknowledge and Assess
- [ ] Acknowledge the PagerDuty incident
- [ ] Check current latency metrics
- [ ] Determine affected endpoints
- [ ] Post in #incidents-performance

### 2. Quick Checks
```bash
# Check current latency
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep http_request_duration

# Check active connections
kubectl exec -n payments deploy/gateway -- netstat -an | grep ESTABLISHED | wc -l

# Check CPU and memory
kubectl top pods -n payments
```

## Investigation Steps

### Step 1: Identify Slow Endpoints
```bash
# Check endpoint latency breakdown
kubectl logs -n payments -l app=gateway --since=15m | grep "request_duration" | awk '{print $3, $8}' | sort -k2 -rn | head -20
```

### Step 2: Check Database Performance
```bash
# Check slow queries
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Check database connections
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

### Step 3: Check External Dependencies
- Payment provider API latency
- Database query performance
- Cache hit rate
- Network latency

### Step 4: Review Resource Utilization
```bash
# Check pod resources
kubectl top pods -n payments

# Check node resources
kubectl top nodes

# Check for throttling
kubectl describe pod -n payments <pod-name> | grep -i throttl
```

## Common Root Causes

### 1. Database Slow Queries
**Symptoms:** High database latency, slow query logs  
**Fix:** Optimize queries, add indexes, or scale database

### 2. External API Timeouts
**Symptoms:** Timeouts to payment providers  
**Fix:** Increase timeout values or implement caching

### 3. Resource Constraints
**Symptoms:** High CPU/memory usage  
**Fix:** Scale horizontally or vertically

### 4. Cache Miss Rate High
**Symptoms:** Low cache hit rate  
**Fix:** Warm up cache or increase cache size

### 5. Network Issues
**Symptoms:** High network latency  
**Fix:** Check network configuration or contact infrastructure team

## Mitigation Steps

### Option 1: Scale Resources
```bash
# Horizontal scaling
kubectl scale deployment/gateway -n payments --replicas=15

# Vertical scaling (update resource limits)
kubectl edit deployment/gateway -n payments
```

### Option 2: Optimize Database
```bash
# Add missing indexes
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "CREATE INDEX CONCURRENTLY idx_payments_created_at ON payments(created_at);"

# Analyze tables
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "ANALYZE payments;"
```

### Option 3: Increase Timeouts
```bash
# Update timeout configuration
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"PAYMENT_TIMEOUT":"30s"}}'
kubectl rollout restart deployment/gateway -n payments
```

### Option 4: Enable Caching
```bash
# Increase cache TTL
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"CACHE_TTL":"300"}}'
kubectl rollout restart deployment/gateway -n payments
```

## Escalation Path

1. **On-call Engineer** - First 15 minutes
2. **Platform Team Lead** - If not improving in 15 minutes
3. **Database Team** - If database-related
4. **Infrastructure Team** - If network/resource-related

## Related Resources

- [Troubleshooting Guide](../docs/troubleshooting-guide.md)
- [Architecture Documentation](../docs/architecture.md)
- [Production Config](../config/production.yaml)
