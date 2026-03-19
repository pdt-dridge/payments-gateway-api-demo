# Security Incident Runbook

## Severity: Critical
**Last Updated:** 2026-03-19  
**Owner:** Security Team  
**Slack Channel:** #security-incidents

## ⚠️ CRITICAL: This is a security incident

## Symptoms
- Unauthorized access detected
- Suspicious API activity
- Data breach alerts
- PagerDuty alert: "Security Incident"

## Initial Response (IMMEDIATE)

### 1. DO NOT DELAY
- [ ] Acknowledge PagerDuty incident
- [ ] **IMMEDIATELY** notify #security-incidents
- [ ] **IMMEDIATELY** page Security Team Lead
- [ ] Do NOT discuss publicly

### 2. Preserve Evidence
- [ ] Do NOT restart services yet
- [ ] Capture current logs
- [ ] Take snapshots of affected systems
- [ ] Document everything

```bash
# Capture logs immediately
kubectl logs -n payments -l app=gateway --since=2h > incident-logs-$(date +%Y%m%d-%H%M%S).log

# Capture current state
kubectl get pods -n payments -o yaml > incident-pods-$(date +%Y%m%d-%H%M%S).yaml
```

## Investigation (WITH SECURITY TEAM)

### Step 1: Assess Impact
- [ ] Identify affected systems
- [ ] Determine data exposure
- [ ] Check for unauthorized access
- [ ] Review audit logs

### Step 2: Contain Threat
```bash
# Isolate affected pods (ONLY with Security Team approval)
kubectl label pod <pod-name> -n payments security-isolated=true

# Block suspicious IPs (ONLY with Security Team approval)
kubectl apply -f security/block-ips.yaml
```

### Step 3: Investigate
- [ ] Review access logs
- [ ] Check for data exfiltration
- [ ] Analyze attack vectors
- [ ] Identify compromised credentials

## Containment Actions (SECURITY TEAM ONLY)

### Rotate All Credentials
```bash
# Rotate API keys
./scripts/rotate-api-keys.sh --all --emergency

# Rotate database passwords
# (Follow security team procedures)

# Invalidate sessions
# (Follow security team procedures)
```

### Isolate Affected Systems
```bash
# Network isolation
kubectl apply -f security/network-policy-lockdown.yaml

# Disable external access
kubectl patch service/gateway -n payments -p '{"spec":{"type":"ClusterIP"}}'
```

## Communication

### Internal (Security Team + Leadership ONLY)
```
🔒 SECURITY INCIDENT
Status: Investigating
Severity: [CRITICAL/HIGH]
Team: Security team engaged
DO NOT SHARE EXTERNALLY
```

### External (ONLY after Security Team approval)
```
We are investigating a security matter.
More information will be provided as appropriate.
```

## Escalation Path

1. **Security Team Lead** - IMMEDIATE
2. **CISO** - Within 5 minutes
3. **Legal Team** - As directed by CISO
4. **Executive Team** - As directed by CISO
5. **External Authorities** - As directed by Legal

## Post-Incident

- [ ] Full forensic analysis
- [ ] Compliance reporting
- [ ] Customer notification (if required)
- [ ] Security improvements

## Related Resources

- Security Team Procedures (Internal Only)
- Incident Response Plan (Internal Only)
- Legal Contact Information (Internal Only)
