# 🚀 Kitten Space Missions - Bicep Infrastructure

Infrastructure as Code para Kitten Space Missions API siguiendo las convenciones de **azure-agent-pro**.

## 📁 Estructura

```
bicep/
├── main.bicep                          # Orquestador principal
├── parameters/
│   └── dev.parameters.json             # Parámetros de desarrollo
└── modules/
    ├── app-service.bicep               # ✅ Nuevo: App Service + Plan con auto-scaling
    └── monitoring.bicep                # ✅ Nuevo: Application Insights + Log Analytics
```

**Módulos reutilizados del repositorio azure-agent-pro:**
- `../../../../bicep/modules/key-vault.bicep` - Key Vault con RBAC
- `../../../../bicep/modules/sql-database.bicep` - SQL Server + Database

## 🏗️ Arquitectura Desplegada

```
┌─────────────────────────────────────────────────────────┐
│              Internet (HTTPS only, TLS 1.2+)             │
└────────────────────────┬────────────────────────────────┘
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
  │            │  │           │  │ • SQL Conn String   │
  │            │  │ FIREWALL: │  │ • Secrets           │
  └────────────┘  │ Allow App │  └─────────────────────┘
                  │ Service   │
                  │ IPs Only  │
                  └─────┬─────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Log Analytics    │
              │   Workspace      │
              │   7-day retention│
              └──────────────────┘
```

## 📋 Recursos Desplegados

| Recurso | Nombre | SKU/Tier | Justificación |
|---------|--------|----------|---------------|
| App Service Plan | `plan-kitten-missions-dev` | B1 (Linux) | Auto-scaling, Always On |
| App Service | `app-kitten-missions-dev` | - | .NET 8.0 runtime |
| SQL Server | `sql-kitten-missions-dev-{unique}` | - | Logical server |
| SQL Database | `sqldb-kitten-missions-dev` | Basic (5 DTU) | Dev workload |
| Key Vault | `kv-kitten-missions-dev-{unique}` | Standard | Secrets management |
| Application Insights | `appi-kitten-missions-dev` | Pay-as-you-go | APM & telemetry |
| Log Analytics | `log-kitten-missions-dev` | PerGB2018 | Centralized logging |

**Costo estimado**: ~$19-20 USD/mes

## 🔧 Prerequisitos

1. **Azure CLI** instalado y autenticado:
   ```bash
   az login
   az account set --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"
   ```

2. **Bicep CLI** instalado:
   ```bash
   az bicep install
   az bicep version
   ```

3. **Permisos** en Azure:
   - Contributor en la subscription o resource group
   - Permisos para crear role assignments

4. **Azure AD Object ID** (para SQL admin):
   ```bash
   az ad signed-in-user show --query id -o tsv
   az ad signed-in-user show --query userPrincipalName -o tsv
   ```

## 🚀 Despliegue

### Paso 1: Configurar Parámetros

Edita `parameters/dev.parameters.json` con tus valores:

```json
{
  "sqlAzureAdAdminObjectId": {
    "value": "<TU_AZURE_AD_OBJECT_ID>"
  },
  "sqlAzureAdAdminUsername": {
    "value": "<TU_EMAIL>"
  }
}
```

Obtén tus valores:
```bash
# Object ID
az ad signed-in-user show --query id -o tsv

# Username
az ad signed-in-user show --query userPrincipalName -o tsv
```

### Paso 2: Crear Resource Group

```bash
az group create \
  --name rg-kitten-missions-dev \
  --location westeurope \
  --tags Environment=dev Project=kitten-space-missions ManagedBy=Azure-Agent-Pro
```

### Paso 3: Validar Bicep

```bash
# Compilar Bicep (verifica sintaxis)
az bicep build --file bicep/main.bicep

# What-if (preview de cambios)
az deployment group what-if \
  --resource-group rg-kitten-missions-dev \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.parameters.json
```

### Paso 4: Desplegar Infraestructura

```bash
az deployment group create \
  --resource-group rg-kitten-missions-dev \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.parameters.json \
  --name deploy-kitten-missions-$(date +%Y%m%d-%H%M%S)
```

**Tiempo estimado**: 8-10 minutos

### Paso 5: Obtener Outputs

```bash
az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT_NAME> \
  --query properties.outputs
```

Outputs importantes:
- `appServiceUrl`: URL de la API
- `appServiceManagedIdentityPrincipalId`: Para asignar permisos SQL
- `keyVaultUri`: URI del Key Vault
- `sqlServerFqdn`: FQDN del SQL Server

## 🔐 Post-Deployment: Configurar SQL Permissions

Después del despliegue, otorga permisos al Managed Identity en SQL Database:

```bash
# Conectar a SQL Database con Azure AD auth
az sql db query \
  --server sql-kitten-missions-dev-<unique> \
  --database sqldb-kitten-missions-dev \
  --auth-method ActiveDirectoryIntegrated \
  --query "
    CREATE USER [app-kitten-missions-dev] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [app-kitten-missions-dev];
    ALTER ROLE db_datawriter ADD MEMBER [app-kitten-missions-dev];
  "
```

O usando SQL Management Studio / Azure Data Studio con Azure AD auth.

## 🧪 Validación Post-Despliegue

### 1. Health Check del App Service

```bash
APP_URL=$(az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT_NAME> \
  --query properties.outputs.appServiceUrl.value -o tsv)

curl -k $APP_URL/health
```

### 2. Verificar SQL Connectivity

```bash
SQL_SERVER=$(az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT_NAME> \
  --query properties.outputs.sqlServerFqdn.value -o tsv)

az sql db show-connection-string \
  --server $SQL_SERVER \
  --name sqldb-kitten-missions-dev \
  --client ado.net
```

### 3. Verificar Application Insights

```bash
AI_KEY=$(az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT_NAME> \
  --query properties.outputs.appInsightsInstrumentationKey.value -o tsv)

echo "Application Insights Key: $AI_KEY"
```

## 🗑️ Cleanup (Eliminar Todo)

```bash
az group delete \
  --name rg-kitten-missions-dev \
  --yes \
  --no-wait
```

## 📊 Monitoreo & Logs

### Application Insights Queries

Accede a Application Insights en Azure Portal o usa KQL:

```kql
// Requests en las últimas 24 horas
requests
| where timestamp > ago(24h)
| summarize count() by bin(timestamp, 1h), resultCode
| render timechart

// Top 10 queries lentas
dependencies
| where type == "SQL"
| where duration > 1000
| top 10 by duration desc
| project timestamp, name, duration, resultCode
```

### Log Analytics Queries

```kql
// App Service HTTP logs
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| where ScStatusCode >= 400
| project TimeGenerated, CsMethod, CsUriStem, ScStatusCode
| order by TimeGenerated desc
```

## 🔧 Troubleshooting

### Error: "SQL firewall rule already exists"

**Solución**: Elimina las reglas duplicadas:
```bash
az sql server firewall-rule list \
  --resource-group rg-kitten-missions-dev \
  --server sql-kitten-missions-dev-<unique>

az sql server firewall-rule delete \
  --name <RULE_NAME> \
  --resource-group rg-kitten-missions-dev \
  --server sql-kitten-missions-dev-<unique>
```

### Error: "Key Vault access denied"

**Solución**: Verifica RBAC assignment:
```bash
az role assignment list \
  --scope /subscriptions/<SUB_ID>/resourceGroups/rg-kitten-missions-dev/providers/Microsoft.KeyVault/vaults/kv-kitten-missions-dev-<unique> \
  --query "[?principalId=='<MANAGED_IDENTITY_PRINCIPAL_ID>']"
```

### App Service no se conecta a SQL

**Solución**: Verifica firewall rules contienen IPs del App Service:
```bash
az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query outboundIpAddresses -o tsv
```

## 📚 Referencias

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [SQL Database Documentation](https://learn.microsoft.com/azure/azure-sql/database/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

## 📝 Convenciones Seguidas

Este código sigue las convenciones del repositorio **azure-agent-pro**:

- ✅ Metadata headers (author, version, description)
- ✅ User-Defined Types para validación
- ✅ Parámetros con decoradores modernos (@description, @minLength, @maxLength)
- ✅ API versions actualizadas (2023-2024)
- ✅ Security by default (TLS 1.2+, Managed Identity, RBAC)
- ✅ Tags estructurados y consistentes
- ✅ System-Assigned Managed Identity
- ✅ Conditional deployment con `if`
- ✅ Outputs descriptivos

## 🐱 Next Steps

1. **Desplegar la aplicación API**:
   - Configurar GitHub Actions para CI/CD
   - Desplegar código .NET a App Service
   
2. **Configurar base de datos**:
   - Ejecutar migraciones Entity Framework
   - Crear tablas (Missions, Astronauts, Telemetry)

3. **Testing**:
   - Smoke tests de endpoints
   - Load testing con Apache Bench o k6

4. **Producción**:
   - Crear `prod.parameters.json`
   - Agregar Private Endpoint para SQL
   - Upgrade App Service Plan a P1v3

---

**Status**: ✅ Ready for deployment  
**Cost**: ~$19-20 USD/month (dev environment)  
**Architecture Decision Record**: [ADR-001](../docs/adr/001-architecture.md)
