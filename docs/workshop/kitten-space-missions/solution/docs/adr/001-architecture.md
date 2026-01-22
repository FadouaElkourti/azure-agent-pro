# ADR-001: Kitten Space Missions API Architecture

**Status**: ✅ Accepted  
**Date**: January 21, 2026  
**Deciders**: Azure_Architect_Pro, MeowTech Engineering Team  
**Context**: Development environment architecture for Kitten Space Missions REST API

---

## Context and Problem Statement

MeowTech Space Agency requires a REST API to manage space missions operated by feline astronauts. The solution must be:
- **Cost-optimized** for development environment (budget constraint: <$25/month)
- **Production-ready patterns** (IaC, CI/CD, monitoring)
- **Secure** (no hardcoded credentials, TLS encryption, audit logging)
- **Scalable** (auto-scaling 1-3 instances)
- **Observable** (Application Insights, centralized logging)

**Key constraint**: Educational/demo project with strict budget limitations while maintaining enterprise-grade practices.

---

## Decision Drivers

- 💰 **Cost**: Hard cap at $25/month for dev environment
- 🔒 **Security**: Zero Trust principles, Managed Identities, encrypted communication
- ⚡ **Performance**: <200ms p95 latency, auto-scaling capability
- 🏗️ **Maintainability**: Infrastructure as Code (Bicep), modular design
- 📊 **Observability**: Full telemetry, centralized logging
- 🚀 **Developer Experience**: No cold starts, Always On functionality

---

## Decisions

### Decision 1: SQL Database with Firewall Rules (No Private Endpoint)

**Decision**: Use Azure SQL Database with IP-based firewall rules instead of Private Endpoint

**Rationale**:
- Private Endpoint costs $7-8/month (~40% of dev budget)
- Firewall rules provide adequate security for dev environment
- SQL Database still enforces TLS 1.2+ encryption
- Azure AD authentication (Managed Identity) eliminates password risks
- Easy to upgrade to Private Endpoint in production

**Implementation**:
```bicep
// SQL Server with restrictive firewall
resource sqlFirewallRules 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = [
  for ip in appServiceOutboundIps: {
    name: 'AllowAppService-${ip}'
    properties: {
      startIpAddress: ip
      endIpAddress: ip
    }
  }
]

// Connection string enforces SSL/TLS
var connectionString = 'Server=tcp:${sqlServer.name}.database.windows.net,1433;Database=${dbName};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;'
```

**Trade-offs**:
- ✅ **Pro**: Saves $7/month (40% budget reduction)
- ✅ **Pro**: Simpler deployment (no VNet/subnet required)
- ✅ **Pro**: Still secure with IP whitelist + TLS + Azure AD
- ⚠️ **Con**: SQL endpoint has public IP (mitigated by firewall)
- ⚠️ **Con**: Not suitable for production (requires PE)

**Reversibility**: HIGH - Easy to add Private Endpoint via Bicep module in production

**Production Plan**: Private Endpoint is **mandatory** for prod deployment

---

### Decision 2: App Service Plan B1 (Not F1 Free)

**Decision**: Use App Service Plan B1 ($12.50/month) instead of F1 Free tier

**Rationale**:
- F1 Free has 60-minute/day CPU time limit (breaks auto-scaling requirement)
- F1 has cold starts after 20 minutes idle (violates <200ms latency SLA)
- F1 doesn't support auto-scaling (requirement: 1-3 instances)
- B1 provides Always On (no cold starts)
- B1 supports custom domains and SSL (future-proof)

**Comparison**:

| Feature | F1 Free | B1 Basic | Decision Impact |
|---------|---------|----------|-----------------|
| Cost/month | $0 | $12.50 | +$12.50 but meets requirements |
| CPU Time | 60 min/day | Unlimited | ✅ No service interruption |
| Always On | ❌ No | ✅ Yes | ✅ No cold starts |
| Auto-scaling | ❌ No | ✅ Yes (1-3) | ✅ Meets requirement |
| Cold starts | ~10-30 sec | None | ✅ <200ms latency achievable |

**Trade-offs**:
- ✅ **Pro**: Meets all functional requirements
- ✅ **Pro**: Consistent performance (no cold starts)
- ✅ **Pro**: Auto-scaling for load handling
- ⚠️ **Con**: $12.50/month vs free (but still under budget)

**Alternatives Considered**:
- **F1 Free**: Rejected due to CPU time limits and cold starts
- **S1 Standard ($70/month)**: Rejected, over budget for dev
- **P1v3 Premium ($70/month)**: Rejected, reserved for production

**Reversibility**: HIGH - Can downgrade to F1 for cost savings if requirements change

---

### Decision 3: Managed Identity for All Authentication

**Decision**: Use System-Assigned Managed Identity for all service-to-service authentication

**Rationale**:
- Zero credentials in code or configuration files
- Azure AD-based authentication (more secure than SQL auth)
- Automatic credential rotation by Azure platform
- Audit logs in Azure AD for compliance
- Follows Zero Trust security principles

**Implementation**:
```bicep
// App Service with System-Assigned Managed Identity
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  identity: {
    type: 'SystemAssigned'
  }
}

// Grant MI access to Key Vault
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// SQL Database with Azure AD admin (Managed Identity)
resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      login: appService.identity.principalId
      sid: appService.identity.principalId
    }
  }
}
```

**Trade-offs**:
- ✅ **Pro**: No password management overhead
- ✅ **Pro**: Automatic credential rotation
- ✅ **Pro**: Audit trail in Azure AD logs
- ⚠️ **Con**: Slightly more complex initial setup vs SQL auth

**Alternatives Considered**:
- **SQL Authentication**: Rejected (password management risk)
- **Service Principal**: Rejected (requires manual secret rotation)
- **User-Assigned MI**: Not needed (single app, single scope)

**Reversibility**: MEDIUM - Switching back to SQL auth is possible but discouraged

---

### Decision 4: SQL Database Basic Tier (5 DTUs)

**Decision**: Use Azure SQL Database Basic tier (5 DTUs, 2GB storage)

**Rationale**:
- Lowest cost tier ($4.60/month)
- Adequate for dev workload (<100 queries/minute expected)
- Automated backups included (7-day retention)
- TDE (Transparent Data Encryption) enabled by default
- Easy to scale up to Standard/Premium in production

**Performance Expectations**:

| Workload | Basic Tier Capacity | Kitten Missions Dev | Status |
|----------|---------------------|---------------------|--------|
| Concurrent queries | ~5-10 | <5 (dev traffic) | ✅ Adequate |
| Queries/second | ~5-10 | <2 (low traffic) | ✅ Adequate |
| Storage | 2 GB | <100 MB expected | ✅ Adequate |
| Response time | 50-200ms | Target <200ms | ✅ Achievable |

**Trade-offs**:
- ✅ **Pro**: Minimal cost ($4.60/month)
- ✅ **Pro**: Sufficient for dev/test workloads
- ✅ **Pro**: Includes backups, TDE, monitoring
- ⚠️ **Con**: Limited DTUs (5) - not suitable for load testing
- ⚠️ **Con**: 2GB storage cap - sufficient for dev only

**Production Plan**: Upgrade to **Standard S2** (50 DTUs, 250GB) for $120/month

**Alternatives Considered**:
- **Serverless SQL**: Rejected ($60/month minimum, over budget)
- **Standard S0**: Rejected ($15/month, not needed for dev)
- **SQL on VM**: Rejected (management overhead, higher cost)

**Reversibility**: HIGH - Easy to scale tier via Bicep parameter change

---

### Decision 5: 7-Day Log Retention (Cost Optimization)

**Decision**: Configure 7-day retention for Log Analytics instead of default 30 days

**Rationale**:
- Reduces storage costs (~$1-2/month savings)
- 7 days sufficient for dev debugging and troubleshooting
- Production will use 90-day retention (compliance requirement)
- Application Insights data separate (not affected)

**Retention Policies**:

| Log Type | Dev Retention | Prod Retention | Rationale |
|----------|---------------|----------------|-----------|
| App Service HTTP logs | 7 days | 90 days | Dev: debug recent issues only |
| SQL diagnostic logs | 7 days | 90 days | Dev: query performance analysis |
| Key Vault audit logs | 30 days | 365 days | Security: always keep longer |
| Application Insights | 90 days | 365 days | APM data: trend analysis needed |

**Trade-offs**:
- ✅ **Pro**: Reduces Log Analytics costs by ~50%
- ✅ **Pro**: 7 days sufficient for dev/test scenarios
- ⚠️ **Con**: Limited historical data for trend analysis
- ⚠️ **Con**: Not compliant for production (requires 90+ days)

**Alternatives Considered**:
- **30-day retention**: Rejected (unnecessary cost for dev)
- **1-day retention**: Rejected (too short for debugging)

**Reversibility**: HIGH - Change retention via Azure Portal or Bicep

---

### Decision 6: Infrastructure as Code with Modular Bicep

**Decision**: Implement 100% IaC using modular Bicep (no Azure Portal deployments)

**Rationale**:
- **Reproducibility**: Deploy identical environments (dev/test/prod)
- **Version Control**: Git history tracks all infrastructure changes
- **CI/CD Integration**: GitHub Actions automated deployments
- **Documentation**: Bicep code serves as infrastructure documentation
- **Disaster Recovery**: Entire environment recreated from code

**Module Structure**:
```
bicep/
├── main.bicep                    # Orchestrator
├── parameters/
│   ├── dev.parameters.json       # Dev-specific config
│   └── prod.parameters.json      # Prod-specific config
└── modules/
    ├── app-service.bicep         # App Service Plan + App
    ├── sql-database.bicep        # SQL Server + DB + Firewall
    ├── key-vault.bicep           # Key Vault + policies
    ├── monitoring.bicep          # App Insights + Log Analytics
    └── rbac.bicep                # Role assignments
```

**Benefits**:
- ✅ **Consistency**: Same infrastructure across environments
- ✅ **Auditability**: Git log = infrastructure audit trail
- ✅ **Collaboration**: PR reviews for infrastructure changes
- ✅ **Speed**: Deploy entire environment in <10 minutes

**Trade-offs**:
- ✅ **Pro**: Full automation, no manual drift
- ✅ **Pro**: Reusable modules across projects
- ⚠️ **Con**: Initial learning curve for Bicep syntax
- ⚠️ **Con**: Some resources easier in Portal (one-off configs)

**Alternatives Considered**:
- **ARM Templates**: Rejected (verbose JSON, poor readability)
- **Terraform**: Rejected (Bicep native to Azure, better Azure feature support)
- **Azure Portal**: Rejected (no version control, manual drift)

**Reversibility**: LOW - Once adopted, reverting to manual Portal is regression

---

### Decision 7: GitHub Actions for CI/CD (Not Azure DevOps)

**Decision**: Use GitHub Actions for CI/CD pipelines with OIDC authentication

**Rationale**:
- Code already hosted on GitHub (single platform)
- OIDC eliminates need for long-lived secrets
- GitHub Environments for deployment approvals
- Integrated with GitHub Issues/PRs (traceability)
- Free for public repos, affordable for private repos

**Pipeline Stages**:
```yaml
validate → build → deploy-dev → deploy-test → deploy-prod
   ↓          ↓         ↓            ↓             ↓
  Bicep    Docker   (auto)    (manual approval) (manual approval)
  lint      build                                + health checks
```

**Trade-offs**:
- ✅ **Pro**: Single platform (GitHub) for code + CI/CD
- ✅ **Pro**: OIDC = no password management
- ✅ **Pro**: Environment protection rules (approvals, gates)
- ⚠️ **Con**: Learning curve if team familiar with Azure DevOps

**Alternatives Considered**:
- **Azure DevOps**: Rejected (separate platform, more overhead)
- **Jenkins**: Rejected (self-hosted infrastructure required)
- **Manual deployments**: Rejected (human error risk)

**Reversibility**: MEDIUM - Can switch to Azure DevOps if organizational policy requires

---

## Consequences

### Positive Consequences

✅ **Cost-Efficient**: Total monthly cost ~$19-20 (well under $25 budget)  
✅ **Secure**: Managed Identity, TLS encryption, firewall rules, Key Vault  
✅ **Scalable**: Auto-scaling 1-3 instances, easy to scale SQL tier  
✅ **Observable**: Application Insights, Log Analytics, centralized logging  
✅ **Maintainable**: 100% IaC (Bicep), version-controlled, modular design  
✅ **Automated**: CI/CD with GitHub Actions, OIDC authentication  
✅ **Production-Ready Patterns**: Easy migration to prod with parameter changes  

### Negative Consequences

⚠️ **SQL Public Endpoint**: Acceptable for dev, **must** use Private Endpoint in prod  
⚠️ **Basic SQL Tier**: Limited performance (5 DTUs), not suitable for load testing  
⚠️ **7-Day Log Retention**: Limited historical data, requires proactive monitoring  
⚠️ **Bicep Learning Curve**: Team needs training if unfamiliar with IaC  

### Mitigation Strategies

| Risk | Mitigation |
|------|-----------|
| SQL public access | Firewall whitelist only App Service IPs, enforce TLS, Azure AD auth |
| SQL performance | Monitor DTU usage, upgrade to Standard S2 if exceeds 80% consistently |
| Short log retention | Set up alerts for critical errors, export logs to blob storage if needed |
| IaC learning curve | Provide Bicep training, code reviews, documentation |

---

## Production Migration Path

When promoting to production, apply these changes:

### Required Changes (Security/Compliance):

| Component | Dev Configuration | Prod Configuration |
|-----------|-------------------|-------------------|
| **SQL Access** | Firewall rules | ✅ **Private Endpoint (mandatory)** |
| **SQL Tier** | Basic (5 DTU) | ✅ **Standard S2 (50 DTU)** minimum |
| **App Service Plan** | B1 | ✅ **P1v3 or higher** (staging slots) |
| **Log Retention** | 7 days | ✅ **90 days minimum** (compliance) |
| **Geo-Redundancy** | None | ✅ **Multi-region deployment** |
| **Monitoring** | Basic alerts | ✅ **PagerDuty, SLO tracking** |
| **WAF** | None | ✅ **Azure Application Gateway + WAF** |

### Estimated Production Cost: $250-300/month

---

## Compliance and Standards

This architecture follows:

- ✅ **Azure Well-Architected Framework**: All 5 pillars addressed
- ✅ **Security Best Practices**: Zero Trust, Managed Identity, TLS 1.2+
- ✅ **Cost Optimization**: Right-sized SKUs, monitoring-driven optimization
- ✅ **Operational Excellence**: IaC, CI/CD, centralized monitoring
- ✅ **Reliability**: Auto-scaling, health checks, automated backups
- ✅ **Performance Efficiency**: <200ms p95 latency target, auto-scaling

---

## Related Documents

- [Architecture Design Document (ADD)](../architecture/ADD-kitten-space-missions.md)
- [Bicep Module: app-service.bicep](../../bicep/modules/app-service.bicep)
- [Bicep Module: sql-database.bicep](../../bicep/modules/sql-database.bicep)
- [CI/CD Workflow](.github/workflows/deploy-kitten-missions.yml)

---

## Approval & Review

**Reviewed By**:
- ✅ Azure Architect: Architecture approved
- ✅ Security Team: Security controls validated (dev-acceptable)
- ✅ FinOps Team: Cost within budget ($19-20/month)
- ✅ Engineering Lead: Functional requirements met

**Approved**: January 21, 2026

**Next Review**: Upon production deployment planning (Q2 2026)

---

## Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-21 | Initial ADR creation | Azure_Architect_Pro |

---

**Status**: ✅ **ACCEPTED** - Ready for implementation

**Implementation Tracking**: [GitHub Issue #1](../../issues/1-kitten-missions-implementation.md)
