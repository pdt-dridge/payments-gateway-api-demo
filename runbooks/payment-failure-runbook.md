# Payment Failure Incident Runbook

## Severity: High
**Last Updated:** 2026-03-19  
**Owner:** Payments Team  
**Slack Channel:** #incidents-payments

## Symptoms
- Payment success rate drops below 95%
- Increased 5xx errors on `/api/v1/payments` endpoint
- Customer reports of failed transactions
- PagerDuty alert: "Payment Success Rate Critical"

## Initial Response (First 5 minutes)

### 1. Acknowledge and Assess
- [ ] Acknowledge the PagerDuty incident
- [ ] Check the alert details for affected region/service
- [ ] Post in #incidents-payments: "Investigating payment failures"
- [ ] Check status page: https://status.example.com

### 2. Quick Health Checks
```bash
# Check service health
curl https://api.payments.example.com/health

# Check recent error logs
kubectl logs -n payments -l app=gateway --tail=100 | grep ERROR

# Check payment success rate (last 5 minutes)
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep payment_success_rate
```

### 3. Verify Recent Changes
- [ ] Check deployments in last 2 hours: `kubectl rollout history -n payments deployment/gateway`
- [ ] Review recent config changes in GitHub
- [ ] Check if any maintenance windows are active

## Investigation Steps

### Step 1: Check External Dependencies

**Payment Provider Status:**
- Stripe: https://status.stripe.com
- PayPal: https://status.paypal.com
- Bank Partner APIs: Check partner status pages

**Database Health:**
```bash
# Check database connections
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT count(*) FROM pg_stat_activity;"

# Check for long-running queries
kubectl exec -n payments deploy/gateway -- psql -h payments-db.prod.internal -U payments -c "SELECT pid, now() - query_start as duration, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC LIMIT 10;"
```

### Step 2: Review Metrics

Access Grafana Dashboard: https://grafana.example.com/d/payments-gateway

**Key Metrics to Check:**
- Payment success rate by provider (Stripe, PayPal, etc.)
- API latency (p50, p95, p99)
- Error rate by endpoint
- Request rate and throughput
- Database connection pool utilization

### Step 3: Analyze Error Patterns

```bash
# Get error breakdown by type
kubectl logs -n payments -l app=gateway --since=30m | grep ERROR | awk '{print $5}' | sort | uniq -c | sort -rn

# Check for specific error codes
kubectl logs -n payments -l app=gateway --since=30m | grep "payment_failed"

# Review application logs in Datadog/Splunk
# Filter by: service:payments-gateway status:error
```

## Common Root Causes

### 1. API Key/Authentication Issues
**Symptoms:** 401/403 errors, "Invalid API key" messages  
**Check:**
```bash
# Verify API key expiration
kubectl get secret -n payments stripe-api-key -o jsonpath='{.data.expiry}' | base64 -d
```
**Fix:** Rotate API keys using `scripts/rotate-api-keys.sh`

### 2. Rate Limiting
**Symptoms:** 429 errors, "Rate limit exceeded"  
**Check:** Review rate limit headers in logs  
**Fix:** Enable circuit breaker or scale up payment processing workers

### 3. Database Connection Pool Exhaustion
**Symptoms:** "Connection pool exhausted", timeouts  
**Check:**
```bash
kubectl exec -n payments deploy/gateway -- curl localhost:8080/metrics | grep db_pool
```
**Fix:** Increase pool size in `config/production.yaml` or restart service

### 4. Payment Provider Outage
**Symptoms:** Timeouts, 503 errors from provider  
**Check:** Provider status pages  
**Fix:** Failover to backup provider or enable maintenance mode

### 5. Recent Deployment Issues
**Symptoms:** Failures started after deployment  
**Check:** Deployment history and recent code changes  
**Fix:** Rollback using `scripts/rollback-deployment.sh`

## Mitigation Steps

### Option 1: Rollback Recent Deployment
```bash
cd scripts
./rollback-deployment.sh payments gateway <previous-version>
```

### Option 2: Rotate API Keys
```bash
cd scripts
./rotate-api-keys.sh stripe
# or
./rotate-api-keys.sh paypal
```

### Option 3: Scale Up Resources
```bash
# Increase replicas
kubectl scale deployment/gateway -n payments --replicas=10

# Increase database connection pool
kubectl edit configmap/gateway-config -n payments
# Update: DB_POOL_SIZE: "50"
kubectl rollout restart deployment/gateway -n payments
```

### Option 4: Enable Maintenance Mode
```bash
# Temporarily disable non-critical payment methods
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"MAINTENANCE_MODE":"true"}}'
kubectl rollout restart deployment/gateway -n payments
```

### Option 5: Failover to Backup Provider
```bash
# Switch from Stripe to PayPal as primary
kubectl patch configmap/gateway-config -n payments --type merge -p '{"data":{"PRIMARY_PROVIDER":"paypal"}}'
kubectl rollout restart deployment/gateway -n payments
```

## Rollback Procedures

### Rollback Deployment
```bash
# View deployment history
kubectl rollout history deployment/gateway -n payments

# Rollback to previous version
kubectl rollout undo deployment/gateway -n payments

# Rollback to specific revision
kubectl rollout undo deployment/gateway -n payments --to-revision=5

# Monitor rollback
kubectl rollout status deployment/gateway -n payments
```

### Rollback Configuration Changes
```bash
# Revert to previous config from Git
git checkout HEAD~1 config/production.yaml
kubectl apply -f config/production.yaml
kubectl rollout restart deployment/gateway -n payments
```

## Communication Templates

### Initial Update (Post in Slack + Status Page)
```
🚨 INCIDENT: Payment Failures
Status: Investigating
Impact: Customers may experience payment failures
Started: [TIME]
Team: Payments team is investigating
Updates: Every 15 minutes
```

### Progress Update
```
📊 UPDATE: Payment Failures
Status: Identified
Root Cause: [BRIEF DESCRIPTION]
Action: [WHAT WE'RE DOING]
ETA: [ESTIMATED TIME TO RESOLUTION]
Next Update: [TIME]
```

### Resolution Update
```
✅ RESOLVED: Payment Failures
Status: Resolved
Resolution: [WHAT WAS DONE]
Duration: [TOTAL TIME]
Impact: [SUMMARY OF IMPACT]
Follow-up: Post-mortem scheduled for [DATE]
```

## Post-Incident Actions

### Immediate (Within 1 hour of resolution)
- [ ] Update status page to "Resolved"
- [ ] Post resolution message in #incidents-payments
- [ ] Document timeline and actions taken
- [ ] Verify all metrics have returned to normal

### Short-term (Within 24 hours)
- [ ] Schedule post-mortem meeting
- [ ] Gather logs and metrics for analysis
- [ ] Notify affected customers if needed
- [ ] Update this runbook with learnings

### Long-term (Within 1 week)
- [ ] Complete post-mortem document
- [ ] Implement action items from post-mortem
- [ ] Update monitoring and alerting if needed
- [ ] Share learnings with broader team

## Escalation Path

1. **On-call Engineer** (You) - First 15 minutes
2. **Payments Team Lead** - If not resolved in 15 minutes
3. **Engineering Manager** - If severity escalates or >30 minutes
4. **VP Engineering** - If customer-facing impact >1 hour
5. **External Vendors** - Contact payment provider support if needed

## Related Resources

- [Architecture Documentation](../docs/architecture.md)
- [API Endpoints](../docs/api-endpoints.md)
- [Troubleshooting Guide](../docs/troubleshooting-guide.md)
- [Production Config](../config/production.yaml)
- [Monitoring Thresholds](../config/monitoring-thresholds.yaml)

## Useful Commands

```bash
# Check payment status for specific transaction
python scripts/check-payment-status.py <payment_id>

# Run full health check
bash scripts/health-check.sh

# View real-time logs
kubectl logs -n payments -l app=gateway -f

# Check pod status
kubectl get pods -n payments

# Describe pod for events
kubectl describe pod -n payments <pod-name>

# Get recent events
kubectl get events -n payments --sort-by='.lastTimestamp'
```

## Notes

- Always communicate early and often during incidents
- Document all actions taken in the PagerDuty incident timeline
- Don't hesitate to escalate if unsure
- Customer impact is the top priority
