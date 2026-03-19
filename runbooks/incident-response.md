# General Incident Response Runbook

## Incident Severity Levels

### P1 - Critical
- Complete service outage
- Data breach or security incident
- Payment processing completely down
- **Response Time:** Immediate
- **Update Frequency:** Every 15 minutes

### P2 - High
- Partial service degradation
- Payment success rate < 95%
- High latency affecting customers
- **Response Time:** Within 15 minutes
- **Update Frequency:** Every 30 minutes

### P3 - Medium
- Minor service issues
- Non-critical feature unavailable
- Performance degradation
- **Response Time:** Within 1 hour
- **Update Frequency:** Every hour

### P4 - Low
- Cosmetic issues
- Non-urgent bugs
- Monitoring alerts
- **Response Time:** Next business day
- **Update Frequency:** As needed

## General Incident Response Process

### 1. Detection & Alert
- PagerDuty alert triggered
- Monitoring system detects issue
- Customer report received

### 2. Acknowledge & Assess (First 5 minutes)
- [ ] Acknowledge PagerDuty incident
- [ ] Determine severity level
- [ ] Post initial message in appropriate Slack channel
- [ ] Assign incident commander (for P1/P2)

### 3. Investigate (First 15 minutes)
- [ ] Check recent deployments
- [ ] Review metrics and logs
- [ ] Identify affected components
- [ ] Determine root cause

### 4. Communicate
- [ ] Post updates in Slack
- [ ] Update status page (for customer-facing issues)
- [ ] Notify stakeholders
- [ ] Keep PagerDuty incident updated

### 5. Mitigate
- [ ] Implement fix or workaround
- [ ] Verify mitigation is effective
- [ ] Monitor for recurrence

### 6. Resolve
- [ ] Confirm issue is resolved
- [ ] Update status page
- [ ] Post resolution message
- [ ] Close PagerDuty incident

### 7. Post-Incident
- [ ] Schedule post-mortem (for P1/P2)
- [ ] Document lessons learned
- [ ] Create action items
- [ ] Update runbooks

## Communication Templates

### Initial Alert
```
🚨 INCIDENT: [Brief Description]
Severity: P[1-4]
Status: Investigating
Impact: [Customer/Internal Impact]
Team: [Team Name] investigating
Updates: Every [frequency]
Incident Link: [PagerDuty URL]
```

### Progress Update
```
📊 UPDATE: [Brief Description]
Status: [Investigating/Identified/Mitigating]
Findings: [What we've learned]
Action: [What we're doing]
ETA: [Estimated resolution time]
Next Update: [Time]
```

### Resolution
```
✅ RESOLVED: [Brief Description]
Duration: [Total time]
Root Cause: [Brief explanation]
Resolution: [What was done]
Follow-up: [Post-mortem/action items]
```

## Escalation Paths

### Technical Escalation
1. On-call Engineer
2. Team Lead
3. Engineering Manager
4. VP Engineering
5. CTO

### Business Escalation
1. Engineering Manager
2. VP Engineering
3. VP Product
4. CEO

### Security Escalation
1. Security Team Lead
2. CISO
3. Legal Team
4. Executive Team

## Tools & Resources

### Monitoring & Observability
- **Grafana:** https://grafana.example.com
- **Datadog:** https://app.datadoghq.com
- **PagerDuty:** https://example.pagerduty.com

### Logs & Traces
- **Splunk:** https://splunk.example.com
- **Jaeger:** https://jaeger.example.com

### Infrastructure
- **Kubernetes Dashboard:** https://k8s.example.com
- **AWS Console:** https://console.aws.amazon.com

### Communication
- **Slack:** #incidents-[team]
- **Status Page:** https://status.example.com
- **Zoom:** Incident war room link

## Best Practices

### Do's
✅ Acknowledge incidents quickly  
✅ Communicate early and often  
✅ Document all actions in PagerDuty  
✅ Focus on mitigation first, root cause second  
✅ Escalate when unsure  
✅ Keep stakeholders informed  

### Don'ts
❌ Don't panic  
❌ Don't make changes without documenting  
❌ Don't assume - verify  
❌ Don't work in isolation  
❌ Don't forget to update status page  
❌ Don't skip post-mortems  

## Post-Mortem Template

### Incident Summary
- **Date:** [Date]
- **Duration:** [Total time]
- **Severity:** P[1-4]
- **Impact:** [Description]

### Timeline
- [Time] - Incident detected
- [Time] - Investigation started
- [Time] - Root cause identified
- [Time] - Mitigation applied
- [Time] - Incident resolved

### Root Cause
[Detailed explanation]

### Resolution
[What was done to resolve]

### Action Items
- [ ] [Action item 1] - Owner: [Name] - Due: [Date]
- [ ] [Action item 2] - Owner: [Name] - Due: [Date]

### Lessons Learned
- What went well
- What could be improved
- What we learned
