# PagerDuty Integration Guide

This guide explains how to set up PagerDuty's GitHub workflow integration and SRE Agent with this repository.

## Overview

This repository is designed to work seamlessly with PagerDuty's:
- **GitHub Workflow Integration**: Automatically fetch relevant files during incidents
- **SRE Agent**: AI-powered incident response assistant with access to your runbooks and documentation

## Prerequisites

- PagerDuty account with Workflows enabled
- GitHub repository with this code
- Admin access to both PagerDuty and GitHub

## Setup Steps

### 1. Connect GitHub to PagerDuty

1. **In PagerDuty:**
   - Go to **Integrations** → **App Integrations**
   - Search for "GitHub"
   - Click **Add** or **Configure**

2. **Authorize GitHub:**
   - Click **Connect to GitHub**
   - Authorize PagerDuty to access your GitHub account
   - Select the repository containing this code

3. **Verify Connection:**
   - Ensure the repository appears in PagerDuty's GitHub integration settings

### 2. Set Up Workflow Actions

#### Example Workflow 1: Payment Failure Alert

**Trigger:** Alert title contains "Payment Failure" OR service = "payments-gateway"

**Actions:**
1. **Fetch Runbook**
   - Action: GitHub - Fetch File
   - Repository: `your-org/payments-gateway-api`
   - Branch: `main`
   - File Path: `runbooks/payment-failure-runbook.md`
   - Add to incident timeline: ✓

2. **Fetch Production Config**
   - Action: GitHub - Fetch File
   - Repository: `your-org/payments-gateway-api`
   - Branch: `main`
   - File Path: `config/production.yaml`
   - Add to incident timeline: ✓

3. **Fetch Health Check Script**
   - Action: GitHub - Fetch File
   - Repository: `your-org/payments-gateway-api`
   - Branch: `main`
   - File Path: `scripts/health-check.sh`
   - Add to incident timeline: ✓

4. **Post to Slack**
   - Action: Slack - Send Message
   - Channel: `#incidents-payments`
   - Message: "Payment failure incident detected. Runbook and config attached to incident."

#### Example Workflow 2: High Latency Alert

**Trigger:** Alert title contains "High Latency" OR metric = "api_latency_p95"

**Actions:**
1. **Fetch Runbook**
   - File Path: `runbooks/high-latency-runbook.md`

2. **Fetch Troubleshooting Guide**
   - File Path: `docs/troubleshooting-guide.md`

3. **Fetch Monitoring Thresholds**
   - File Path: `config/monitoring-thresholds.yaml`

#### Example Workflow 3: Security Incident

**Trigger:** Alert title contains "Security" OR severity = "critical" AND service = "payments-gateway"

**Actions:**
1. **Fetch Security Runbook**
   - File Path: `runbooks/security-incident-runbook.md`

2. **Escalate Immediately**
   - Action: PagerDuty - Escalate
   - Escalation Policy: Security Team

3. **Post to Slack**
   - Channel: `#security-incidents`
   - Message: "🔒 SECURITY INCIDENT - Security team has been paged"

### 3. Configure SRE Agent

#### Add Repository as Knowledge Source

1. **In PagerDuty:**
   - Go to **SRE Agent** → **Knowledge Sources**
   - Click **Add Knowledge Source**
   - Select **GitHub Repository**

2. **Configure Repository:**
   - Repository: `your-org/payments-gateway-api`
   - Branch: `main`
   - Include paths:
     - `runbooks/`
     - `docs/`
     - `config/`
     - `README.md`
   - Exclude paths:
     - `scripts/`
     - `src/`
     - `.git/`

3. **Set Permissions:**
   - Read access: ✓
   - Auto-sync: ✓ (sync every 6 hours)

4. **Test Knowledge:**
   - Ask SRE Agent: "What should I do if payment success rate drops?"
   - Verify it references the payment-failure-runbook.md

#### Configure SRE Agent Prompts

Add custom prompts to help SRE Agent understand your context:

**System Prompt:**
```
You are an SRE assistant for the Payments Gateway API. When responding to incidents:
1. Always reference the relevant runbook from the repository
2. Provide specific kubectl commands when applicable
3. Include links to monitoring dashboards
4. Remind responders to update the incident timeline
5. Suggest escalation if the issue persists beyond the timeframes in the runbook
```

**Example Questions to Train:**
- "What's the first step for a payment failure?"
- "How do I check database connection pool status?"
- "What are the alert thresholds for API latency?"
- "How do I rollback a deployment?"

### 4. File Organization for PagerDuty

This repository is organized to work optimally with PagerDuty:

```
payments-gateway-api/
├── runbooks/              # Incident response procedures
│   ├── payment-failure-runbook.md
│   ├── high-latency-runbook.md
│   ├── security-incident-runbook.md
│   └── incident-response.md
├── config/                # Configuration files for context
│   ├── production.yaml
│   ├── staging.yaml
│   └── monitoring-thresholds.yaml
├── docs/                  # Reference documentation
│   ├── architecture.md
│   ├── api-endpoints.md
│   └── troubleshooting-guide.md
├── scripts/               # Operational scripts
│   ├── health-check.sh
│   ├── rollback-deployment.sh
│   ├── rotate-api-keys.sh
│   └── check-payment-status.py
└── src/                   # Sample source code
    └── payment-processor.py
```

**File Naming Conventions:**
- Runbooks: `{incident-type}-runbook.md`
- Configs: `{environment}.yaml`
- Scripts: `{action}-{resource}.sh`

## Testing the Integration

### Test Workflow Execution

1. **Create a Test Incident:**
   - In PagerDuty, manually create an incident
   - Title: "Test: Payment Failure"
   - Service: payments-gateway

2. **Verify Workflow Runs:**
   - Check incident timeline for fetched files
   - Verify runbook appears in timeline
   - Confirm Slack message was sent

3. **Test SRE Agent:**
   - Open the incident
   - Ask SRE Agent: "What should I do first?"
   - Verify it references the payment-failure-runbook.md

### Test File Fetching

Use PagerDuty's workflow testing feature:

1. Go to **Workflows** → Select your workflow
2. Click **Test**
3. Provide sample alert data
4. Verify files are fetched correctly

## Best Practices

### 1. Keep Runbooks Updated
- Review runbooks after each incident
- Update with new learnings
- Remove outdated information

### 2. Use Clear File Names
- Use descriptive names that match incident types
- Follow consistent naming conventions
- Organize files logically

### 3. Include Context
- Add timestamps to configuration files
- Document why settings are configured a certain way
- Include links to related resources

### 4. Version Control
- Commit changes with clear messages
- Tag important versions
- Use branches for major updates

### 5. Test Regularly
- Test workflows monthly
- Verify file paths are correct
- Ensure content is accessible

## Workflow Triggers

### By Alert Title
```
Alert title contains "Payment Failure" → Fetch payment-failure-runbook.md
Alert title contains "High Latency" → Fetch high-latency-runbook.md
Alert title contains "Security" → Fetch security-incident-runbook.md
```

### By Service
```
Service = "payments-gateway" → Fetch relevant runbooks
Service = "database" → Fetch database troubleshooting
```

### By Severity
```
Severity = "critical" → Fetch all runbooks + config
Severity = "high" → Fetch specific runbook
```

## Troubleshooting PagerDuty Integration

### Issue: Files Not Fetching

**Check:**
- Repository name is correct
- Branch name is correct (usually `main` or `master`)
- File path is correct (case-sensitive)
- PagerDuty has access to the repository

### Issue: Wrong File Retrieved

**Check:**
- File path in workflow configuration
- Branch is correct
- File hasn't been moved or renamed

### Issue: SRE Agent Can't Access Files

**Check:**
- Repository is added as knowledge source
- Permissions are configured correctly
- Files are in supported format (Markdown, YAML, etc.)

## Example Incident Flow

1. **Alert Triggered:** "Payment Success Rate Critical"
2. **PagerDuty Creates Incident**
3. **Workflow Automatically Runs:**
   - Fetches `payment-failure-runbook.md`
   - Fetches `config/production.yaml`
   - Fetches `scripts/health-check.sh`
4. **Responder Opens Incident:**
   - Sees runbook in timeline
   - Follows step-by-step instructions
   - References configuration for context
   - Runs health check script
5. **SRE Agent Assists:**
   - Answers questions about the system
   - Provides additional context
   - Suggests next steps

## Maintenance

### Weekly
- [ ] Review recent incidents
- [ ] Update runbooks if gaps found
- [ ] Test one workflow

### Monthly
- [ ] Review all runbooks for accuracy
- [ ] Update configuration files
- [ ] Test all workflows
- [ ] Review SRE Agent knowledge base

### Quarterly
- [ ] Major runbook review
- [ ] Update architecture documentation
- [ ] Review and update thresholds
- [ ] Team training on runbooks

## Additional Resources

- [PagerDuty Workflows Documentation](https://support.pagerduty.com/docs/workflows)
- [PagerDuty SRE Agent Documentation](https://support.pagerduty.com/docs/sre-agent)
- [GitHub Integration Guide](https://support.pagerduty.com/docs/github-integration)

## Support

For questions about this integration:
- **PagerDuty Support:** support@pagerduty.com
- **Internal Team:** #devops-support

---

**Last Updated:** 2026-03-19  
**Maintained By:** DevOps Team
