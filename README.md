# Payments Gateway API

A demo payments gateway API for testing PagerDuty workflow integrations and SRE Agent capabilities.

## Overview

This repository contains a sample payments gateway API with associated runbooks, configuration files, and troubleshooting resources designed for incident response workflows.

## Repository Structure

```
payments-gateway-api/
├── README.md
├── runbooks/          # Incident response runbooks
├── config/            # Configuration files
├── docs/              # Documentation and guides
├── scripts/           # Operational scripts
└── src/               # Sample source code
```

## Quick Links

### Runbooks
- [Payment Failure Runbook](runbooks/payment-failure-runbook.md)
- [High Latency Runbook](runbooks/high-latency-runbook.md)
- [Security Incident Runbook](runbooks/security-incident-runbook.md)
- [General Incident Response](runbooks/incident-response.md)

### Documentation
- [Architecture Overview](docs/architecture.md)
- [API Endpoints](docs/api-endpoints.md)
- [Troubleshooting Guide](docs/troubleshooting-guide.md)

### Configuration
- [Production Config](config/production.yaml)
- [Staging Config](config/staging.yaml)
- [Monitoring Thresholds](config/monitoring-thresholds.yaml)

## PagerDuty Integration

This repository is designed to work with PagerDuty's GitHub workflow integration. During an incident, you can automatically retrieve:

- **Runbooks**: Step-by-step incident response procedures
- **Configuration Files**: Current production settings and thresholds
- **Scripts**: Diagnostic and remediation tools
- **Documentation**: Architecture and troubleshooting guides

## Usage with PagerDuty SRE Agent

The PagerDuty SRE Agent can access this repository to:
1. Retrieve relevant runbooks based on alert type
2. Pull configuration files for context
3. Access diagnostic scripts
4. Reference API documentation

## Getting Started

1. Clone this repository
2. Configure PagerDuty GitHub integration
3. Set up workflow actions to fetch files during incidents
4. Test with sample incidents

## Support

For questions about this demo repository, contact your DevOps team.
