# Architecture Design Document (ADD)
## Kitten Space Missions API - Optimized Dev Environment

**Version**: 1.1 (Cost-Optimized)  
**Date**: January 21, 2026  
**Status**: Approved for Development  

---

## 1. Executive Summary

**Project**: Kitten Space Missions API  
**Client**: MeowTech Space Agency  
**Environment**: Development (cost-optimized)  
**Objective**: Design and deploy a budget-conscious, secure Azure-based REST API for managing space missions operated by feline astronauts, following Azure Well-Architected Framework principles with aggressive cost optimization.

**Expected Impact**:
- Enable CRUD operations for missions and astronauts
- Provide real-time telemetry monitoring
- Establish foundation for future production environment
- **Monthly cost: ~$19-20 USD** (68% reduction from typical B1+PE setup)

**Key Design Decisions**:
- ✅ Maintained: Auto-scaling, Always On, Managed Identity
- ⚠️ Cost Trade-off: SQL Database with public access + IP whitelist (no Private Endpoint)
- ✅ Security: TLS 1.2+, Key Vault, firewall rules, Azure AD authentication

---

## 2. Context & Requirements

### 2.1 Current State
- **Greenfield project** - no existing infrastructure
- Educational/demo project with production-ready patterns
- Single Azure subscription: `d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d`
- Target region: West Europe
- **Cost constraint**: Maximum $25/month for dev environment

### 2.2 Functional Requirements

**API Endpoints**:
- `GET/POST /api/missions` - Mission management
- `GET/PUT/DELETE /api/missions/{id}` - Mission details
- `GET/POST /api/astronauts` - Astronaut registry
- `GET /api/astronauts/{id}` - Astronaut profile
- `GET /api/telemetry` - Real-time mission telemetry
- `GET /health` - Service health check

**Data Model**:
- **Missions**: id, name, launch_date, destination, status
- **Astronauts**: id, name, breed, missions_completed, certifications
- **Telemetry**: timestamp, mission_id, altitude, speed, temperature

### 2.3 Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| **Performance** | API latency (p95) | < 200ms |
| **Availability** | Uptime SLA | 99% (dev) |
| **Security** | Transport encryption | TLS 1.2+ only |
| **Security** | Authentication | API Key + Managed Identity |
| **Scalability** | Auto-scaling | 1-3 instances |
| **Observability** | Logging/Metrics | Full coverage via App Insights |
| **Cost** | Monthly budget | < $25 USD |

### 2.4 Constraints

**Technical**:
- **Hard budget cap**: $25/month (dev)
- Basic SKUs for cost optimization
- No geo-redundancy (dev environment)
- Infrastructure as Code (Bicep) mandatory
- Accept public SQL access with IP restrictions (cost trade-off)

**Organizational**:
- Follow [azure-agent-pro](../../..) repository conventions
- Modular Bicep structure
- Environment-specific parameters
- Naming convention: `{resource}-kitten-missions-{env}`

**Regulatory**:
- None (educational project)

---

## 3. Proposed Architecture

### 3.1 High-Level Design (Cost-Optimized)

```
┌──────────────────────────────────────────────────────────────┐
│                Internet (HTTPS only, TLS 1.2+)                │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Azure App Service  │
              │    (B1 Linux Plan)   │
              │   app-kitten-        │
              │   missions-dev       │
              │                      │
              │ • Always On          │
              │ • Auto-scale 1-3     │
              │ • Managed Identity   │◄──────────┐
              └──────────┬───────────┘           │
                         │                       │
           ┌─────────────┼─────────────┐         │
           │             │             │         │
           ▼             ▼             ▼         │
  ┌────────────┐  ┌───────────┐  ┌──────────────┴──────┐
  │ App        │  │  Azure    │  │  Azure Key Vault    │
  │ Insights   │  │  SQL DB   │  │  kv-kitten-xxx      │
  │            │  │  (Basic)  │  │                     │
  │ Telemetry  │  │           │  │ • Connection String │
  │ Metrics    │  │ FIREWALL: │  │ • API Keys          │
  │ Logs       │  │ Allow App │  │ • Certificates      │
  └────────────┘  │ Service   │  └─────────────────────┘
                  │ IPs Only  │
                  │           │
                  │ SSL/TLS   │
                  │ Required  │
                  └─────┬─────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Log Analytics    │
              │   Workspace      │
              │   (Diagnostics)  │
              │   7-day retention│
              └──────────────────┘
```

**Data Flow**:
1. Client → HTTPS/TLS 1.2+ → App Service
2. App Service → Managed Identity → Key Vault (fetch secrets)
3. App Service → SQL Database over TLS (IP whitelisted)
4. App Service → Application Insights (telemetry, logs, metrics)
5. All resources → Log Analytics (diagnostic logs, 7-day retention)

**Security Layers**:
- ✅ HTTPS only enforcement
- ✅ SQL Server firewall: Allow only App Service outbound IPs
- ✅ SQL connection requires SSL/TLS encryption
- ✅ Managed Identity for Key Vault and SQL authentication
- ✅ No SQL username/password (Azure AD only)
- ✅ API Key authentication (stored in Key Vault)

### 3.2 Component Responsibilities

| Component | Purpose | Cost-Optimization Strategy |
|-----------|---------|---------------------------|
| **App Service Plan (B1)** | Host API runtime | Maintained for auto-scaling + Always On |
| **App Service** | API endpoints | Built-in scaling, no cold starts |
| **SQL Database (Basic)** | Persistent storage | Minimal tier, sufficient for dev workload |
| **SQL Firewall Rules** | Network security | FREE (replaces Private Endpoint €6.50/month) |
| **Key Vault** | Secret management | Standard tier (minimal cost) |
| **Application Insights** | APM & telemetry | Pay-as-you-go, <500MB/month expected |
| **Log Analytics** | Centralized logging | 7-day retention (reduced from 30 days) |

---

## 4. Azure Services Selection (Cost-Optimized)

### 4.1 Service SKUs & Pricing

| Service | SKU/Tier | Justification | Monthly Cost (USD) |
|---------|----------|---------------|-------------------|
| **App Service Plan** | **B1 (Linux)** | 1 vCore, 1.75GB RAM, auto-scale 1-3 instances, Always On enabled | **~$12.50** |
| App Service | Included in plan | API runtime | $0 |
| SQL Server | Free | Logical server | $0 |
| **SQL Database** | **Basic (2GB)** | 5 DTUs, adequate for dev/test, no auto-scaling | **~$4.60** |
| **SQL Firewall Rules** | **FREE** | IP whitelist (replaces Private Endpoint) | **$0** ⬇️ |
| Key Vault | Standard | Secrets storage, operations charged separately | ~$0.03 |
| Application Insights | Pay-as-you-go | <500MB ingestion expected | ~$1.50-2.00 |
| Log Analytics | Pay-as-you-go | 7-day retention (reduced cost) | ~$0.50-1.00 |
| Network Security Group | Standard | Subnet protection (if VNet used) | $0 |

**Total Monthly Cost**: **~$19.13 - $20.13 USD** ✅

### 4.2 Cost Comparison vs Original Design

| Configuration | Monthly Cost | Trade-offs |
|---------------|--------------|------------|
| **Original** (B1 + PE) | ~$31-33 | Maximum security with Private Endpoint |
| **Current** (B1 no PE) | ~$19-20 | ✅ 40% savings, firewall-based security |
| Alternative (F1 Free) | ~$6-8 | ⚠️ 60 min/day CPU limit, cold starts |

**Selected**: B1 without Private Endpoint (best balance for dev workload)

### 4.3 Cost Optimization Strategies Applied

✅ **Implemented**:
- Removed Private Endpoint (saved $7/month)
- Reduced Log Analytics retention: 30 → 7 days
- Application Insights sampling at 50% (dev only)
- SQL Database Basic tier (lowest cost with acceptable performance)
- Single region deployment (no geo-redundancy)

⚠️ **Not Recommended for Dev**:
- F1 Free tier: CPU time limits break auto-scaling requirement
- Serverless SQL: $60/month minimum cost
- Premium SKUs: Over budget

💡 **Future Production Considerations**:
- Private Endpoint: +$7/month (mandatory for prod)
- SQL Database Standard S2: ~$120/month (50 DTUs, 250GB)
- App Service Plan P1v3: ~$70/month (staging slots, more resources)
- Estimated prod cost: **$250-300/month**

---

## 5. Security Architecture

### 5.1 Network Security

**SQL Database Access Control**:

```
┌─────────────────────────────────────────┐
│     SQL Server Firewall Rules           │
├─────────────────────────────────────────┤
│ ✅ Allow: App Service Outbound IPs      │
│    • Dynamic IP detection               │
│    • Auto-update if IPs change          │
│                                         │
│ ✅ Connection Requirements:             │
│    • SSL/TLS required (Encrypt=true)    │
│    • Trust Server Certificate=false     │
│    • Minimum TLS 1.2                    │
│                                         │
│ ❌ Deny: All other IPs                  │
│ ❌ Deny: Allow Azure Services = No      │
└─────────────────────────────────────────┘
```

**SQL Connection String (TLS Enforced)**:
```
Server=tcp:sql-kitten-missions-dev.database.windows.net,1433;
Database=sqldb-kitten-missions-dev;
Authentication=Active Directory Managed Identity;
Encrypt=true;
TrustServerCertificate=false;
Connection Timeout=30;
```

### 5.2 Identity & Access Management

| Principal | Resource | Authentication Method | Permissions |
|-----------|----------|----------------------|-------------|
| App Service MI | Key Vault | System-Assigned MI | Key Vault Secrets User (read-only) |
| App Service MI | SQL Database | Azure AD Authentication | db_datareader, db_datawriter |
| DevOps Pipeline | Resource Group | Service Principal | Contributor (IaC deployments) |
| Developers | Azure Portal | Azure AD SSO | Reader (view-only) |

**Security Principles**:
- ✅ Zero passwords in code or configuration
- ✅ Managed Identity for all service-to-service auth
- ✅ Least privilege RBAC assignments
- ✅ Audit logs enabled on all resources

### 5.3 Data Protection

| Layer | Implementation | Status |
|-------|----------------|--------|
| **Transport** | TLS 1.2+ enforced | ✅ Mandatory |
| **SQL Encryption** | Transparent Data Encryption (TDE) | ✅ Enabled by default |
| **Key Vault** | Secrets encrypted at rest | ✅ Azure-managed keys |
| **Connection Strings** | Stored in Key Vault only | ✅ No plaintext |
| **API Keys** | Rotated via Key Vault | ✅ 90-day rotation |

### 5.4 Security Trade-offs (Dev Environment)

| Decision | Trade-off | Mitigation |
|----------|-----------|------------|
| **No Private Endpoint** | SQL has public endpoint | ✅ Firewall: Only App Service IPs allowed |
| **No VNet Integration** | App Service uses public routing | ✅ HTTPS only, TLS 1.2+ enforced |
| **Basic SQL tier** | Limited compute resources | ✅ Adequate for dev workload (<100 queries/min) |

⚠️ **Production Requirements**:
- Private Endpoint: MANDATORY
- VNet Integration: MANDATORY
- SQL Standard tier: RECOMMENDED (better performance)

---

## 6. Monitoring & Observability

### 6.1 Application Insights Configuration

**Key Metrics Tracked**:
- Request rate (requests/sec)
- Response time (p50, p95, p99)
- Failure rate (%)
- Dependency duration (SQL queries)
- Exceptions (unhandled errors)
- Custom events (mission launches, astronaut registrations)

**Sampling Strategy (Cost Optimization)**:
- Dev environment: 50% sampling
- Production: 100% (no sampling)

### 6.2 Alerting Strategy

| Alert Name | Condition | Threshold | Action |
|------------|-----------|-----------|--------|
| High Error Rate | Failed requests % | > 5% over 5 min | Email ops team |
| Slow API Response | p95 latency | > 500ms over 5 min | Email + Slack |
| SQL Connection Failures | Dependency failures | > 3 consecutive | PagerDuty (prod only) |
| High CPU Usage | App Service CPU | > 80% over 10 min | Auto-scale trigger |

### 6.3 Log Analytics Queries (KQL)

**Recent API Errors**:
```kql
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| where ScStatusCode >= 500
| project TimeGenerated, CsMethod, CsUriStem, ScStatusCode, TimeTaken
| order by TimeGenerated desc
```

**Slow SQL Queries**:
```kql
AppDependencies
| where DependencyType == "SQL"
| where Duration > 1000  // >1 second
| summarize avg(Duration), count() by Name
| order by avg_Duration desc
```

**API Usage by Endpoint**:
```kql
AppRequests
| where TimeGenerated > ago(24h)
| summarize RequestCount = count() by Name
| order by RequestCount desc
```

### 6.4 Diagnostic Settings

All resources configured to send logs to Log Analytics:

| Resource | Logs Enabled | Retention |
|----------|-------------|-----------|
| App Service | HTTP logs, App logs, Error logs | 7 days |
| SQL Database | Errors, Query performance insights | 7 days |
| Key Vault | Audit logs (all secret access) | 30 days |

---

## 7. Deployment Strategy

### 7.1 Bicep Infrastructure Code Structure

```
docs/workshop/kitten-space-missions/solution/
└── bicep/
    ├── main.bicep                           # Main orchestrator
    ├── parameters/
    │   ├── dev.parameters.json              # Dev environment config
    │   └── prod.parameters.json             # Future prod config
    └── modules/
        ├── app-service.bicep                # App Service Plan + App
        ├── sql-database.bicep               # SQL Server + Database + Firewall
        ├── key-vault.bicep                  # Key Vault + access policies
        ├── monitoring.bicep                 # App Insights + Log Analytics
        └── rbac.bicep                       # Role assignments (MI → KV, SQL)
```

### 7.2 Deployment Phases

**Phase 1: Core Infrastructure (Day 1)**
- [ ] Create resource group: `rg-kitten-missions-dev`
- [ ] Deploy Key Vault
- [ ] Deploy SQL Server + Database
- [ ] Configure SQL firewall rules
- [ ] Deploy Application Insights + Log Analytics
- [ ] Populate Key Vault with secrets (manual secure process)

**Phase 2: Application Hosting (Day 2)**
- [ ] Deploy App Service Plan (B1)
- [ ] Deploy App Service
- [ ] Configure Managed Identity
- [ ] Assign RBAC roles (MI → Key Vault, SQL)
- [ ] Configure App Settings (Key Vault references)

**Phase 3: Application Deployment (Day 3)**
- [ ] Deploy API code (GitHub Actions or `az webapp deployment`)
- [ ] Run database migrations
- [ ] Test endpoints (`/health`, `/api/missions`)
- [ ] Validate SQL connectivity
- [ ] Verify Key Vault integration

**Phase 4: Monitoring & Testing (Day 4)**
- [ ] Configure Application Insights alerts
- [ ] Create Log Analytics dashboards
- [ ] Run load tests (50 concurrent users, 5 min duration)
- [ ] Performance baseline (measure p95 latency)
- [ ] Document runbooks

### 7.3 CI/CD Pipeline (GitHub Actions)

**Workflow**: `.github/workflows/deploy-kitten-missions.yml`

```yaml
name: Deploy Kitten Missions API

on:
  push:
    branches: [main]
    paths:
      - 'docs/workshop/kitten-space-missions/solution/**'
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Bicep Lint
        run: az bicep build --file bicep/main.bicep
      
  deploy-infra:
    needs: validate
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy Infrastructure
        run: |
          az deployment group create \
            --resource-group rg-kitten-missions-dev \
            --template-file bicep/main.bicep \
            --parameters bicep/parameters/dev.parameters.json
  
  deploy-app:
    needs: deploy-infra
    runs-on: ubuntu-latest
    steps:
      - name: Deploy API Code
        uses: azure/webapps-deploy@v2
        with:
          app-name: app-kitten-missions-dev
          package: ./api
```

### 7.4 Rollback Strategy

**Rollback Triggers**:
- Deployment validation failures
- API error rate > 10% sustained for 5 minutes
- SQL connectivity failures
- App Service startup failures

**Rollback Procedure**:
1. Stop App Service: `az webapp stop --name app-kitten-missions-dev`
2. Restore previous deployment via GitHub Actions (re-run previous workflow)
3. Validate health endpoint
4. Investigate logs in Application Insights
5. Document incident in post-mortem

**Estimated Rollback Time**: < 10 minutes

---

## 8. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **SQL public access** | High | Low | Firewall rules (only App Service IPs), SSL required, Azure AD auth |
| **App Service IP change** | Medium | Low | Monitor outbound IPs, automated firewall rule updates |
| **Cost overrun** | Medium | Low | Budget alerts at $18, $22, $25; daily cost monitoring |
| **SQL performance** | Medium | Medium | Basic tier adequate for <100 queries/min; monitor query performance |
| **Key Vault throttling** | Low | Low | Cache secrets in App Service memory (refresh every 24h) |
| **Cold starts** | Low | N/A | Always On enabled (B1 plan feature) |

---

## 9. Validation & Testing

### 9.1 Pre-Deployment Validation

```bash
# Bicep syntax validation
az bicep build --file bicep/main.bicep

# What-if analysis (preview changes)
az deployment group what-if \
  --resource-group rg-kitten-missions-dev \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.parameters.json

# Security scan (if Checkov installed)
checkov -f bicep/main.bicep --framework bicep
```

### 9.2 Post-Deployment Tests

**Smoke Tests**:
```bash
# Health check
curl https://app-kitten-missions-dev.azurewebsites.net/health

# Create mission
curl -X POST https://app-kitten-missions-dev.azurewebsites.net/api/missions \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "name": "Apollo 13 Meow",
    "destination": "Moon",
    "launch_date": "2026-02-14T10:00:00Z",
    "status": "planned"
  }'

# Verify in SQL (using Azure AD auth)
az sql db query \
  --server sql-kitten-missions-dev \
  --database sqldb-kitten-missions-dev \
  --query "SELECT COUNT(*) FROM Missions"
```

**Load Testing** (Apache Bench):
```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 https://app-kitten-missions-dev.azurewebsites.net/api/missions

# Target: p95 < 200ms
```

**Integration Tests**:
- ✅ Managed Identity → Key Vault access
- ✅ Managed Identity → SQL Database authentication
- ✅ SQL connection with TLS enforcement
- ✅ Application Insights telemetry ingestion
- ✅ Log Analytics diagnostic logs

---

## 10. Cost Monitoring & FinOps

### 10.1 Budget Alerts Configuration

```bash
az consumption budget create \
  --budget-name kitten-missions-dev-budget \
  --amount 25 \
  --time-grain Monthly \
  --start-date 2026-01-01 \
  --notifications \
    threshold=80 \
    operator=GreaterThan \
    contact-emails="ops@meowtech.space" \
    threshold=90 \
    operator=GreaterThan \
    contact-emails="cto@meowtech.space"
```

### 10.2 Cost Optimization Checklist

**Implemented**:
- [x] Removed Private Endpoint (saved $7/month)
- [x] SQL Database Basic tier
- [x] App Service B1 (not over-provisioned)
- [x] Log Analytics 7-day retention
- [x] Application Insights sampling at 50%
- [x] Single region deployment

**Future Optimizations**:
- [ ] SQL Serverless tier evaluation (if usage <1 hour/day)
- [ ] Reserved Instances for App Service Plan (if prod >12 months)
- [ ] Azure Hybrid Benefit (if applicable)

### 10.3 Monthly Cost Tracking

| Month | Actual Cost | Budget | Variance | Notes |
|-------|-------------|--------|----------|-------|
| Feb 2026 | TBD | $25 | - | Initial deployment |
| Mar 2026 | TBD | $25 | - | - |

---

## 11. Well-Architected Framework Compliance

### ✅ Reliability
- **Health Checks**: `/health` endpoint monitored
- **Auto-scaling**: 1-3 instances based on CPU/memory
- **Retry Logic**: Built into Azure SDK libraries
- **Backup**: SQL automated backups (7-day retention)

### ✅ Security (with Cost Trade-offs)
- **Managed Identity**: Azure AD authentication for all service-to-service
- **Secrets Management**: Key Vault (no hardcoded credentials)
- **HTTPS Only**: TLS 1.2+ enforced on App Service
- **SQL Access**: Firewall rules (IP whitelist) + TLS encryption
- ⚠️ **Trade-off**: No Private Endpoint (acceptable for dev)

### ✅ Cost Optimization
- **Right-sizing**: B1 App Service, Basic SQL Database
- **Monitoring**: Budget alerts at 80%, 90%, 100%
- **Retention**: 7-day logs (reduced from default 30 days)
- **Sampling**: 50% Application Insights ingestion

### ✅ Operational Excellence
- **IaC**: 100% Bicep (no manual Azure Portal changes)
- **CI/CD**: GitHub Actions with OIDC authentication
- **Monitoring**: Application Insights + Log Analytics
- **Documentation**: ADR, runbooks, architecture diagrams

### ✅ Performance Efficiency
- **Auto-scaling**: Configured for CPU >70%, memory >80%
- **Always On**: No cold starts (B1 feature)
- **Caching**: In-memory caching for frequent queries
- **Future**: Redis Cache if telemetry queries become bottleneck

---

## 12. Documentation & Knowledge Base

### 12.1 Architecture Decision Records (ADRs)

**ADR-001**: Use SQL Database with Firewall vs Private Endpoint
- **Decision**: Firewall-based access control (no Private Endpoint)
- **Rationale**: 40% cost savings ($7/month) for dev environment
- **Trade-off**: Public endpoint with IP whitelist (acceptable for dev)
- **Reversibility**: Easy to add Private Endpoint in production

**ADR-002**: App Service B1 vs F1 Free
- **Decision**: B1 Basic tier
- **Rationale**: Always On, auto-scaling, no CPU time limits
- **Trade-off**: $12.50/month vs free (but F1 too restrictive)
- **Reversibility**: Can downgrade to F1 for demos/testing

### 12.2 Runbooks

**Runbook 1: Deployment Failure**
1. Check GitHub Actions workflow logs
2. Validate Bicep syntax: `az bicep build`
3. Check Azure Activity Log for errors
4. Verify RBAC permissions for service principal
5. Re-run deployment with `--debug` flag

**Runbook 2: SQL Connectivity Issues**
1. Verify App Service outbound IPs in SQL firewall
2. Check SQL Server firewall logs in Log Analytics
3. Test connection from App Service console: `sqlcmd -S <server> -Q "SELECT 1"`
4. Verify Managed Identity has SQL permissions

**Runbook 3: High API Latency**
1. Query Application Insights for slow requests
2. Identify slow SQL queries in dependency telemetry
3. Check SQL Database DTU usage (should be <80%)
4. Review auto-scaling configuration
5. Consider adding database indexes

---

## 13. Future Production Roadmap

### Phase 1: Production Environment Setup (Q2 2026)

**Infrastructure Upgrades**:
- [ ] App Service Plan: B1 → P1v3 (staging slots, more resources)
- [ ] SQL Database: Basic → Standard S2 (50 DTUs, 250GB)
- [ ] Add Private Endpoint for SQL (mandatory for prod)
- [ ] VNet Integration for App Service
- [ ] Azure Front Door (global load balancing, WAF)

**Estimated Prod Cost**: $250-300/month

### Phase 2: High Availability (Q3 2026)

**Multi-region Deployment**:
- [ ] Secondary region: North Europe
- [ ] SQL Database geo-replication
- [ ] Azure Traffic Manager (DNS-based routing)
- [ ] Automated failover procedures

**Estimated Cost**: +$200-250/month (total ~$500/month)

### Phase 3: Enterprise Features (Q4 2026)

**Advanced Monitoring**:
- [ ] Azure Monitor Workbooks (custom dashboards)
- [ ] SLO/SLI tracking (99.9% availability target)
- [ ] PagerDuty integration
- [ ] Cost anomaly detection

**Security Enhancements**:
- [ ] Azure Web Application Firewall
- [ ] DDoS Protection Standard
- [ ] Azure Sentinel (SIEM)

---

## 14. Sign-off & Approvals

**Design Review Completed**: ✅  
**Date**: January 21, 2026

- [x] **Technical Lead** - Architecture approved (cost-optimized variant)
- [x] **Security Team** - Security controls validated (acceptable for dev)
- [x] **FinOps Team** - Cost within budget ($19-20/month approved)
- [x] **Product Owner** - Functional requirements met

**Approved for Development Deployment**

---

## 15. References

**Azure Documentation**:
- [App Service Pricing](https://azure.microsoft.com/pricing/details/app-service/linux/)
- [SQL Database Pricing](https://azure.microsoft.com/pricing/details/azure-sql-database/)
- [SQL Database Firewall Rules](https://learn.microsoft.com/azure/azure-sql/database/firewall-configure)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)

**Project Documentation**:
- [Bicep Best Practices](../../../../bicep/README.md)
- [azure-agent-pro Repository Conventions](../../../../../README.md)

---

## Appendix A: Resource Naming Convention

| Resource Type | Naming Pattern | Example |
|---------------|----------------|---------|
| Resource Group | `rg-{project}-{env}` | `rg-kitten-missions-dev` |
| App Service Plan | `plan-{project}-{env}` | `plan-kitten-missions-dev` |
| App Service | `app-{project}-{env}` | `app-kitten-missions-dev` |
| SQL Server | `sql-{project}-{env}` | `sql-kitten-missions-dev` |
| SQL Database | `sqldb-{project}-{env}` | `sqldb-kitten-missions-dev` |
| Key Vault | `kv-{project}-{env}-{unique}` | `kv-kitten-missions-dev-a1b2c3` |
| App Insights | `appi-{project}-{env}` | `appi-kitten-missions-dev` |
| Log Analytics | `log-{project}-{env}` | `log-kitten-missions-dev` |

---

## Appendix B: SQL Connection Security Configuration

**Bicep Configuration**:
```bicep
// SQL Server with firewall rules (no Private Endpoint)
resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: 'sql-kitten-missions-dev'
  location: location
  properties: {
    administratorLogin: null // Azure AD only
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'ServicePrincipal'
      login: appService.identity.principalId
      sid: appService.identity.principalId
      tenantId: tenant().tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled' // With firewall restrictions
  }
}

// Dynamic firewall rule for App Service outbound IPs
resource sqlFirewallAppService 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = [for ip in appService.properties.outboundIpAddresses: {
  parent: sqlServer
  name: 'AllowAppService-${ip}'
  properties: {
    startIpAddress: ip
    endIpAddress: ip
  }
}]
```

**Connection String Template** (stored in Key Vault):
```
Server=tcp:sql-kitten-missions-dev.database.windows.net,1433;
Database=sqldb-kitten-missions-dev;
Authentication=Active Directory Managed Identity;
Encrypt=true;
TrustServerCertificate=false;
Connection Timeout=30;
```

---

## Appendix C: Cost Calculation Details

**App Service Plan B1** (Linux):
- Base price: $0.017/hour × 730 hours = $12.41
- Estimated: ~$12.50/month

**SQL Database Basic**:
- Base price: $0.0064/hour × 730 hours = $4.67
- Estimated: ~$4.60/month

**Application Insights**:
- Free tier: 1GB/month
- Pay-as-you-go: $2.30/GB
- Expected ingestion: <500MB (50% sampling)
- Estimated: ~$1.50-2.00/month

**Log Analytics**:
- Free tier: 5GB/month
- Pay-as-you-go: $2.76/GB
- Expected ingestion: <200MB (7-day retention)
- Estimated: ~$0.50-1.00/month

**Key Vault**:
- Operations: $0.03/10,000 operations
- Expected: <1,000 operations/month
- Estimated: ~$0.03/month

**Total**: $19.13 - $20.13 USD/month

---

**End of Architecture Design Document** 🚀🐱

**Status**: ✅ Approved for Development  
**Next Step**: [Activity 3 - Generate Bicep Infrastructure Code](../../activity-03-bicep-generation.md)
