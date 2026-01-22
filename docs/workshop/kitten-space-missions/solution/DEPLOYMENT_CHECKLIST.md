# 🐱🚀 Kitten Space Missions - Deployment Checklist

**Project**: Kitten Space Missions API  
**Client**: MeowTech Space Agency  
**Environment**: Development  
**Date**: 2024  
**Estimated Deployment Time**: 15-20 minutes  

---

## ✅ Pre-Deployment Checklist

### 1. Prerequisites Verification

- [ ] **Azure CLI** installed and updated (`az --version`)
- [ ] **Bicep CLI** installed (`az bicep version`)
- [ ] **Azure subscription** active
  - Subscription ID: `d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d`
  - Verify access: `az account show`
- [ ] **Permissions** verified:
  - Contributor role on subscription/resource group
  - Ability to create resources
  - Azure AD user permissions
- [ ] **Repository** cloned and updated
  - Location: `/home/fadoua/repos/github/workshop/azure-agent-pro`

### 2. Configuration Preparation

- [ ] **Obtain Azure AD credentials** (run these commands):
  ```bash
  # Get your Object ID
  az ad signed-in-user show --query id -o tsv
  
  # Get your User Principal Name
  az ad signed-in-user show --query userPrincipalName -o tsv
  ```

- [ ] **Update parameters file**: `bicep/parameters/dev.parameters.json`
  - Replace `<YOUR_AZURE_AD_OBJECT_ID>` with actual Object ID
  - Replace `<YOUR_USERNAME@DOMAIN.COM>` with actual User Principal Name

- [ ] **Review configuration values**:
  - Project Name: `kitten-missions`
  - Environment: `dev`
  - Location: `westeurope`

### 3. Validation

- [ ] **Run validation script**:
  ```bash
  cd docs/workshop/kitten-space-missions/solution
  ./validate-bicep.sh
  ```

- [ ] **Check Bicep syntax** (manual if needed):
  ```bash
  az bicep build --file bicep/main.bicep
  az bicep build --file bicep/modules/app-service.bicep
  az bicep build --file bicep/modules/monitoring.bicep
  ```

- [ ] **Verify module dependencies exist**:
  - `../../../../bicep/modules/key-vault.bicep`
  - `../../../../bicep/modules/sql-database.bicep`

---

## 🚀 Deployment Steps

### Phase 1: Resource Group Creation

- [ ] **Create resource group**:
  ```bash
  az group create \
    --name rg-kitten-missions-dev \
    --location westeurope \
    --tags \
      Environment=dev \
      Project=kitten-missions \
      ManagedBy=Bicep \
      Owner=fadoua
  ```

- [ ] **Verify creation**:
  ```bash
  az group show --name rg-kitten-missions-dev
  ```

### Phase 2: What-If Analysis

- [ ] **Run what-if deployment**:
  ```bash
  az deployment group what-if \
    --resource-group rg-kitten-missions-dev \
    --template-file bicep/main.bicep \
    --parameters bicep/parameters/dev.parameters.json
  ```

- [ ] **Review what-if output**:
  - Expected resources to create: 9-10
    - Log Analytics Workspace
    - Application Insights
    - App Service Plan
    - App Service
    - Key Vault
    - SQL Server
    - SQL Database
    - Firewall Rules (dynamic count)
    - RBAC Assignments
    - Key Vault Secrets

- [ ] **Verify no unexpected deletions or modifications**

### Phase 3: Infrastructure Deployment

- [ ] **Deploy infrastructure** (8-10 minutes):
  ```bash
  az deployment group create \
    --resource-group rg-kitten-missions-dev \
    --template-file bicep/main.bicep \
    --parameters bicep/parameters/dev.parameters.json \
    --name "deployment-$(date +%Y%m%d-%H%M%S)"
  ```

- [ ] **Monitor deployment progress**:
  ```bash
  # In another terminal
  watch -n 5 'az deployment group list \
    --resource-group rg-kitten-missions-dev \
    --query "[0].{Name:name, State:properties.provisioningState, Duration:properties.duration}" \
    -o table'
  ```

- [ ] **Deployment succeeded** (check output for "Succeeded")

### Phase 4: Capture Outputs

- [ ] **Retrieve deployment outputs**:
  ```bash
  az deployment group show \
    --resource-group rg-kitten-missions-dev \
    --name $(az deployment group list \
      --resource-group rg-kitten-missions-dev \
      --query "[0].name" -o tsv) \
    --query properties.outputs
  ```

- [ ] **Save important values**:
  - App Service URL: `______________________________`
  - App Service Name: `______________________________`
  - App Insights Instrumentation Key: `______________________________`
  - SQL Server FQDN: `______________________________`
  - SQL Database Name: `______________________________`
  - Key Vault URI: `______________________________`
  - Managed Identity Principal ID: `______________________________`

---

## 🔧 Post-Deployment Configuration

### Phase 5: SQL Database Permissions

- [ ] **Connect to SQL Database** (using Azure AD authentication):
  ```bash
  sqlcmd -S sql-kitten-missions-dev.database.windows.net \
    -d sqldb-kitten-missions-dev \
    -G \
    -U <YOUR_USERNAME@DOMAIN.COM>
  ```

- [ ] **Grant Managed Identity permissions** (run in sqlcmd):
  ```sql
  -- Create user for App Service Managed Identity
  CREATE USER [app-kitten-missions-dev] FROM EXTERNAL PROVIDER;
  
  -- Grant read/write permissions
  ALTER ROLE db_datareader ADD MEMBER [app-kitten-missions-dev];
  ALTER ROLE db_datawriter ADD MEMBER [app-kitten-missions-dev];
  
  -- Grant execute permissions for stored procedures (if needed)
  ALTER ROLE db_ddladmin ADD MEMBER [app-kitten-missions-dev];
  
  -- Verify permissions
  SELECT dp.name AS [User], dp.type_desc, 
         drm.role_principal_id, roles.name AS [Role]
  FROM sys.database_principals AS dp
  LEFT JOIN sys.database_role_members AS drm 
    ON dp.principal_id = drm.member_principal_id
  LEFT JOIN sys.database_principals AS roles 
    ON drm.role_principal_id = roles.principal_id
  WHERE dp.name = 'app-kitten-missions-dev';
  ```

- [ ] **Exit sqlcmd**: `exit`

### Phase 6: Verification Tests

- [ ] **Health endpoint check**:
  ```bash
  APP_URL=$(az deployment group show \
    --resource-group rg-kitten-missions-dev \
    --name $(az deployment group list \
      --resource-group rg-kitten-missions-dev \
      --query "[0].name" -o tsv) \
    --query properties.outputs.appServiceUrl.value -o tsv)
  
  curl -f "$APP_URL/health" || echo "⚠️ App not deployed yet"
  ```

- [ ] **SQL connectivity test** (from local):
  ```bash
  sqlcmd -S sql-kitten-missions-dev.database.windows.net \
    -d sqldb-kitten-missions-dev \
    -G \
    -Q "SELECT @@VERSION;"
  ```

- [ ] **Key Vault access test**:
  ```bash
  az keyvault secret show \
    --vault-name kv-kitten-missions-dev \
    --name sql-connection-string \
    --query value -o tsv
  ```

- [ ] **Application Insights data flow**:
  ```bash
  az monitor app-insights component show \
    --app appi-kitten-missions-dev \
    --resource-group rg-kitten-missions-dev \
    --query connectionString
  ```

### Phase 7: Monitoring Setup

- [ ] **Configure alerts** (optional, via Azure Portal or additional Bicep):
  - High CPU usage (>80%)
  - High memory usage (>80%)
  - Slow response time (p95 >1s)
  - HTTP 5xx errors (>10/min)

- [ ] **Test Application Insights**:
  - Navigate to Azure Portal → Application Insights
  - Check "Live Metrics" for real-time data
  - Verify "Application Map" shows dependencies

---

## 📊 Cost Verification

- [ ] **Check current spending**:
  ```bash
  az consumption usage list \
    --start-date $(date -d '1 day ago' +%Y-%m-%d) \
    --end-date $(date +%Y-%m-%d) \
    --query "[?contains(instanceName, 'kitten-missions')].{Resource:instanceName, Cost:pretaxCost}" \
    -o table
  ```

- [ ] **Verify budget alignment**:
  - Expected monthly cost: **$19-20 USD**
  - Budget threshold: **$50-100 USD**
  - Current projection: `$______` (within budget ✅ / over budget ❌)

- [ ] **Enable cost alerts** (optional):
  ```bash
  # Create budget
  az consumption budget create \
    --budget-name "kitten-missions-dev-budget" \
    --amount 50 \
    --category Cost \
    --time-grain Monthly \
    --resource-group rg-kitten-missions-dev \
    --notifications \
      threshold=80 \
      operator=GreaterThan \
      contact-emails=<YOUR_EMAIL>
  ```

---

## 🧹 Cleanup (Optional - For Test Deployments)

- [ ] **Delete resource group** (⚠️ irreversible):
  ```bash
  az group delete \
    --name rg-kitten-missions-dev \
    --yes \
    --no-wait
  ```

- [ ] **Verify deletion**:
  ```bash
  az group exists --name rg-kitten-missions-dev
  # Should return: false
  ```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue 1: "sqlAzureAdAdminObjectId parameter not provided"
**Solution**: Update `bicep/parameters/dev.parameters.json` with actual Azure AD Object ID

#### Issue 2: "SQL Server firewall rules blocking connection"
**Solution**: Bicep creates dynamic firewall rules for App Service outbound IPs. For local development, add your IP:
```bash
MY_IP=$(curl -s ifconfig.me)
az sql server firewall-rule create \
  --resource-group rg-kitten-missions-dev \
  --server sql-kitten-missions-dev \
  --name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

#### Issue 3: "App Service can't connect to SQL Database"
**Solution**: Verify Managed Identity permissions in SQL (see Phase 5)

#### Issue 4: "Key Vault access denied"
**Solution**: Check RBAC assignment exists:
```bash
az role assignment list \
  --scope $(az keyvault show \
    --name kv-kitten-missions-dev \
    --query id -o tsv) \
  --query "[?principalId=='<MANAGED_IDENTITY_PRINCIPAL_ID>']"
```

---

## 📚 Additional Resources

- **Architecture Design Document**: `docs/architecture/ADD-kitten-space-missions.md`
- **Architecture Decisions**: `docs/adr/001-architecture.md`
- **Deployment Guide**: `bicep/README.md`
- **Validation Script**: `validate-bicep.sh`

---

## ✅ Deployment Sign-Off

**Deployed by**: `______________________________`  
**Date**: `______________________________`  
**Time**: `______________________________`  
**Deployment duration**: `_______ minutes`  
**Issues encountered**: `______________________________`  
**Status**: ✅ Success / ⚠️ Partial / ❌ Failed  

**Notes**:
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

**Next Steps**: Deploy application code (API implementation) following application deployment guide.
