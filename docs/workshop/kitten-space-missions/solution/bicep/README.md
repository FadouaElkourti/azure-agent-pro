# 🏗️ Kitten Space Missions - Infrastructure as Code (Bicep)

**Versión**: 1.0.0  
**Fecha**: 2026-01-22  
**Costo estimado**: $19.13/mes (dev)

---

## 📋 Tabla de Contenidos

1. [Descripción General](#-descripción-general)
2. [Estructura de Archivos](#-estructura-de-archivos)
3. [Arquitectura de Módulos](#-arquitectura-de-módulos)
4. [Naming Conventions](#-naming-conventions)
5. [Pre-requisitos](#-pre-requisitos)
6. [Validación y Testing](#-validación-y-testing)
7. [Despliegue](#-despliegue)
8. [Variables de Entorno](#-variables-de-entorno)
9. [Post-Deployment](#-post-deployment)
10. [Troubleshooting](#-troubleshooting)
11. [Seguridad y Compliance](#-seguridad-y-compliance)

---

## 🎯 Descripción General

Este proyecto contiene la **Infrastructure as Code (IaC)** para desplegar la API de Kitten Space Missions en Azure. Utiliza **Azure Bicep** con una arquitectura modular y reutilizable que sigue las mejores prácticas de seguridad, observabilidad y FinOps.

### Recursos Desplegados

| Recurso | SKU/Tier | Propósito | Costo Mensual |
|---------|----------|-----------|---------------|
| **App Service Plan** | B1 Basic | Hosting de la API | $12.41 |
| **App Service** | - | Aplicación .NET 8.0 | Incluido |
| **SQL Database** | Basic (2GB) | Base de datos | $4.99 |
| **SQL Server** | - | Servidor lógico | Gratis |
| **Key Vault** | Standard | Gestión de secretos | $0.23 |
| **Log Analytics** | Pay-as-you-go | Centralización de logs | $1.00 |
| **Application Insights** | Pay-as-you-go | APM y monitoreo | $0.50 |
| **TOTAL** | | | **$19.13/mes** |

### Características Clave

✅ **Seguridad**: Managed Identities, Azure AD auth only, TLS 1.2+, secretos en Key Vault  
✅ **Observabilidad**: Diagnostic settings en todos los recursos, Application Insights integrado  
✅ **FinOps**: SKUs optimizados para dev, auto-scaling configurado, tags de cost allocation  
✅ **Modularidad**: 4 módulos reutilizables independientes  
✅ **Compliance**: Logging de auditoría, encryption at rest (TDE), backup automático

---

## 📁 Estructura de Archivos

```
bicep/
├── README.md                          # Este archivo
├── main.bicep                         # Orquestador principal (234 líneas)
├── main.json                          # ARM template compilado (auto-generado)
├── modules/
│   ├── app-service.bicep              # App Service + Plan (385 líneas)
│   ├── key-vault.bicep                # Key Vault con access policies (145 líneas)
│   ├── sql-database.bicep             # SQL Server + Database (210 líneas)
│   └── monitoring.bicep               # Log Analytics + App Insights (existente)
└── parameters/
    └── dev.parameters.json            # Parámetros para entorno dev
```

### Responsabilidad de Cada Módulo

#### `main.bicep` (Orquestador)
- **Responsabilidad**: Coordinar el despliegue de todos los módulos en el orden correcto
- **Scope**: `resourceGroup`
- **Recursos directos**: 
  - SQL Firewall Rule (AllowAzureServices)
  - Key Vault Secret (SQL connection string)
- **Módulos invocados**: monitoring, appService, keyVault, sqlDatabase
- **Outputs**: 13 outputs (URLs, FQDNs, IDs, connection strings)

#### `modules/monitoring.bicep`
- **Responsabilidad**: Plataforma centralizada de observabilidad
- **Recursos**:
  - Log Analytics Workspace (PerGB2018, 7 días retención)
  - Application Insights (50% sampling para cost optimization)
- **Outputs**: workspace ID, instrumentation key, connection string
- **Dependencias**: Ninguna (se despliega primero)

#### `modules/app-service.bicep`
- **Responsabilidad**: Hosting de la aplicación .NET 8.0
- **Recursos**:
  - App Service Plan B1 (1 vCPU, 1.75GB RAM, Linux)
  - App Service (managed identity, HTTPS only, TLS 1.2)
  - Auto-scaling rules (CPU-based, 1-3 instancias)
  - Diagnostic settings → Log Analytics
- **Outputs**: app name, hostname, managed identity principal ID, outbound IPs
- **Dependencias**: monitoring (para App Insights connection)

#### `modules/key-vault.bicep`
- **Responsabilidad**: Gestión segura de secretos y claves
- **Recursos**:
  - Key Vault Standard (soft delete 7 días, sin purge protection en dev)
  - Access policy para App Service managed identity (get/list secrets)
  - Diagnostic settings → Log Analytics
- **Outputs**: Key Vault ID, name, URI
- **Dependencias**: appService (necesita principalId del managed identity)

#### `modules/sql-database.bicep`
- **Responsabilidad**: Base de datos relacional con Azure AD auth
- **Recursos**:
  - SQL Server (Azure AD admin only, sin SQL authentication)
  - SQL Database Basic (5 DTU, 2GB)
  - Transparent Data Encryption (TDE) habilitado
  - Diagnostic settings → Log Analytics (server y database)
- **Outputs**: server FQDN, database name, connection string template
- **Dependencias**: monitoring (para diagnostic settings)

---

## 🔗 Arquitectura de Módulos

### Diagrama de Dependencias (Simplificado)

```
main.bicep
├── monitoring.bicep (Log Analytics, App Insights) ⚡ Sin dependencias - Deploy First
├── app-service.bicep → dependsOn: monitoring
│   ├── App Service Plan (B1 Linux)
│   ├── App Service (Managed Identity)
│   └── Auto-scaling rules
├── key-vault.bicep → dependsOn: app-service, monitoring
│   ├── Key Vault (Standard)
│   └── Access Policy para App Service MI
├── sql-database.bicep → dependsOn: monitoring
│   ├── SQL Server (Azure AD only)
│   ├── SQL Database (Basic, 2GB)
│   └── TDE enabled
├── [Direct] SQL Firewall Rule → dependsOn: sql-database
│   └── AllowAzureServices
└── [Direct] Key Vault Secret → dependsOn: key-vault, sql-database
    └── SqlConnectionString
```

### Diagrama de Dependencias (Detallado)

```
main.bicep (Orquestador)
│
├─→ monitoring.bicep (⚡ Deploy First)
│   ├── Log Analytics Workspace (PerGB2018, 7 días retention)
│   └── Application Insights (50% sampling)
│
├─→ appService.bicep
│   ├── App Service Plan (B1, 1 vCPU, 1.75GB RAM, Linux)
│   ├── App Service (managed identity, HTTPS only, TLS 1.2)
│   ├── Auto-scaling (CPU-based, 1-3 instances)
│   └── Diagnostic settings → Log Analytics
│       ↑ depende de: monitoring
│
├─→ keyVault.bicep
│   ├── Key Vault Standard (soft delete 7d, sin purge protection)
│   ├── Access Policy → App Service (get/list secrets)
│   └── Diagnostic settings → Log Analytics
│       ↑ depende de: appService (principalId), monitoring
│
├─→ sqlDatabase.bicep
│   ├── SQL Server (Azure AD admin only, sin SQL auth)
│   ├── SQL Database Basic (5 DTU, 2GB)
│   ├── TDE habilitado
│   └── Diagnostic settings → Log Analytics (server + database)
│       ↑ depende de: monitoring
│
├── SQL Firewall Rule (recurso directo en main.bicep)
│   └── AllowAzureServices (0.0.0.0 → 0.0.0.0)
│       ↑ depende de: sqlDatabase
│
└── Key Vault Secret (recurso directo en main.bicep)
    └── SqlConnectionString (Azure AD Managed Identity format)
        ↑ depende de: keyVault, sqlDatabase
```

### Orden de Despliegue

1. **monitoring** → Se despliega primero (sin dependencias)
2. **appService** → Necesita monitoring (App Insights)
3. **keyVault** → Necesita appService (managed identity)
4. **sqlDatabase** → Necesita monitoring (diagnostic settings)
5. **Recursos directos** → SQL firewall rule, KV secret (al final)

**Nota**: Bicep infiere automáticamente las dependencias basándose en referencias de outputs (ej: `monitoring.outputs.logAnalyticsWorkspaceId`). Los `dependsOn` explícitos se han eliminado para seguir best practices.

---

## 🏷️ Naming Conventions

Este proyecto sigue las **Azure Naming Conventions** estándar:

### Formato General

```
{tipo-recurso}-{proyecto}-{entorno}[-{región}][-{uniqueString}]
```

### Tabla de Convenciones

| Tipo de Recurso | Prefijo | Ejemplo | Global? |
|-----------------|---------|---------|---------|
| Resource Group | `rg-` | `rg-kitten-missions-dev` | No |
| App Service Plan | `plan-` | `plan-kitten-missions-dev` | No |
| App Service | `app-` | `app-kitten-missions-dev` | Sí* |
| SQL Server | `sql-` | `sql-kitten-missions-dev-7bt5ye` | Sí |
| SQL Database | `sqldb-` | `sqldb-kitten-missions-dev` | No |
| Key Vault | `kv-` | `kv-kitten-missions-dev-7bt5ye` | Sí |
| Log Analytics | `log-` | `log-kitten-missions-dev` | No |
| App Insights | `appi-` | `appi-kitten-missions-dev` | No |

\* *App Service tiene DNS global (`app-kitten-missions-dev.azurewebsites.net`)*

### UniqueString para Recursos Globales

Para recursos con nombres globalmente únicos (SQL Server, Key Vault), se añade un sufijo generado:

```bicep
var uniqueSuffix = uniqueString(resourceGroup().id)
// Genera: "7bt5ye" (6 caracteres, determinístico por RG)

var sqlServerName = 'sql-${projectName}-${environment}-${uniqueSuffix}'
// Resultado: sql-kitten-missions-dev-7bt5ye
```

**Ventaja**: El nombre es **predecible** y **reproducible** si se recrea el RG con el mismo ID.

---

## ✅ Pre-requisitos

### 1. Azure CLI

```bash
# Verificar instalación
az --version

# Debe ser >= 2.20.0 (para soporte Bicep)
# Si no está instalado:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Suscripción de Azure

```bash
# Login
az login

# Listar subscriptions
az account list --query "[].{Name:name, ID:id, State:state}" -o table

# Seleccionar subscription
az account set --subscription "TU-SUBSCRIPTION-NAME-O-ID"

# Verificar
az account show --query "{Name:name, ID:id}" -o table
```

### 3. Permisos Requeridos

Necesitas rol **Contributor** o **Owner** en:
- La subscription (si creas el RG desde Bicep)
- O el Resource Group existente

```bash
# Verificar roles actuales
az role assignment list \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  -o table
```

### 4. Resource Group

```bash
# Crear resource group (si no existe)
az group create \
  --name rg-kitten-missions-dev \
  --location westeurope \
  --tags Environment=Development Project=KittenSpaceMissions ManagedBy=Bicep
```

### 5. Azure AD Object ID (para SQL Admin)

El SQL Server requiere un administrador de Azure AD. Obtén tu Object ID:

```bash
# Obtener tu Azure AD Object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
USER_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

echo "Azure AD Object ID: $USER_OBJECT_ID"
echo "Azure AD UPN: $USER_UPN"
```

**Actualiza `parameters/dev.parameters.json`** con estos valores:

```json
{
  "sqlAzureAdAdminObjectId": {
    "value": "TU-OBJECT-ID-AQUI"
  },
  "sqlAzureAdAdminUsername": {
    "value": "tu-email@company.com"
  }
}
```

---

## ✅ Validación y Testing

### 1. Validación de Sintaxis

```bash
cd docs/workshop/kitten-space-missions/solution/bicep

# Compilar main.bicep (valida sintaxis)
az bicep build --file main.bicep

# Si hay errores, los mostrará aquí
# Si OK, genera main.json (ARM template)
```

**Output esperado**:
```
✓ Bicep compilation successful
```

### 2. Validar Módulos Individualmente

```bash
# Validar cada módulo por separado
az bicep build --file modules/monitoring.bicep
az bicep build --file modules/app-service.bicep
az bicep build --file modules/key-vault.bicep
az bicep build --file modules/sql-database.bicep
```

### 3. Linting (Análisis Estático)

```bash
# Ejecutar linter (busca anti-patterns)
az bicep lint --file main.bicep
```

**Warnings comunes (pueden ignorarse)**:
- `no-unused-params`: Parámetro no usado (OK si planeas usarlo después)
- `prefer-interpolation`: Estilo de código (opcional)

**Errores críticos (corregir)**:
- `secure-secrets-in-params`: Falta @secure en passwords
- `no-hardcoded-location`: Location hardcodeado

### 4. What-If Deployment (Pre-flight Check)

**What-If** muestra qué cambios se harían **SIN desplegar realmente**:

```bash
# Preview de cambios (sin desplegar)
az deployment group what-if \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --result-format FullResourcePayloads
```

**Output esperado**:
```
Resource changes: 15 to create, 0 to modify, 0 to delete.

+ Microsoft.Web/serverfarms/plan-kitten-missions-dev
  location: "westeurope"
  sku.name: "B1"
  
+ Microsoft.Sql/servers/sql-kitten-missions-dev-7bt5ye
  location: "westeurope"
  properties.azureADOnlyAuthentication: true
  
... (más recursos)
```

**Validaciones**:
- ✅ Número de recursos: ~15 (OK)
- ✅ Naming correcto: `kitten-missions-dev` en todos
- ✅ Location: `westeurope` en todos
- ✅ SKUs: B1 (App Service), Basic (SQL)
- ✅ Sin errores de dependencias

### 5. Validación de Template (Sin What-If)

Si what-if falla, intenta validación básica:

```bash
az deployment group validate \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json
```

---

## 🚀 Despliegue

### Método 1: Deployment Interactivo (Recomendado para Dev)

```bash
cd docs/workshop/kitten-space-missions/solution/bicep

# Desplegar infraestructura
az deployment group create \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --mode Incremental \
  --verbose
```

**Duración estimada**: 5-10 minutos

**Outputs al finalizar**:
```json
{
  "appServiceUrl": "https://app-kitten-missions-dev.azurewebsites.net",
  "sqlServerFqdn": "sql-kitten-missions-dev-7bt5ye.database.windows.net",
  "keyVaultUri": "https://kv-kitten-missions-dev-7bt5ye.vault.azure.net/"
}
```

### Método 2: Deployment con Confirmación What-If

```bash
# 1. Ejecutar what-if primero
az deployment group what-if \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json

# 2. Revisar output

# 3. Si OK, desplegar
az deployment group create \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json
```

### Método 3: Deployment con Tag de Versión

```bash
# Desplegar con tag de versión para tracking
az deployment group create \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters tags='{"Version":"1.0.0","DeployedBy":"'$(whoami)'","DeploymentDate":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'
```

### Verificar Deployment

```bash
# Listar deployments recientes
az deployment group list \
  --resource-group rg-kitten-missions-dev \
  --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
  -o table

# Ver outputs del último deployment
az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT-NAME> \
  --query properties.outputs
```

### Rollback (En Caso de Error)

Si el deployment falla, puedes revertir:

```bash
# Listar deployments
az deployment group list \
  --resource-group rg-kitten-missions-dev \
  -o table

# Re-desplegar deployment previo exitoso
az deployment group create \
  --resource-group rg-kitten-missions-dev \
  --name rollback-$(date +%s) \
  --template-file main.bicep \
  --parameters @previous-working-params.json
```

---

## 🔧 Variables de Entorno

### Parámetros Requeridos (en dev.parameters.json)

| Parámetro | Tipo | Descripción | Valor Dev | Valor Prod |
|-----------|------|-------------|-----------|------------|
| `projectName` | string | Nombre del proyecto | `kitten-missions` | `kitten-missions` |
| `environment` | string | Entorno | `dev` | `prod` |
| `location` | string | Azure region | `westeurope` | `westeurope` |
| `sqlAzureAdAdminObjectId` | string | Object ID del admin SQL | *Tu Object ID* | *DBA Group ID* |
| `sqlAzureAdAdminUsername` | string | UPN del admin SQL | *Tu email* | *DBA Group* |
| `tags` | object | Tags para recursos | Ver abajo | Ver abajo |

### Tags Estándar

```json
{
  "tags": {
    "value": {
      "Environment": "Development",
      "Project": "KittenSpaceMissions",
      "ManagedBy": "Bicep",
      "CostCenter": "Engineering",
      "Owner": "team@company.com",
      "CreatedBy": "bicep-template",
      "CreatedDate": "2026-01-22",
      "Purpose": "kitten-space-missions-api"
    }
  }
}
```

### Variables de Runtime (No en Parámetros)

Estas variables se generan automáticamente en Bicep:

```bicep
var uniqueSuffix = uniqueString(resourceGroup().id)  // "7bt5ye"
var resourceNames = {
  appService: 'app-${projectName}-${environment}'
  sqlServer: 'sql-${projectName}-${environment}-${uniqueSuffix}'
  // ...
}
```

### Secretos en Key Vault (Post-Deployment)

Después del despliegue, estos secretos estarán disponibles en Key Vault:

| Secret Name | Descripción | Formato |
|-------------|-------------|---------|
| `SqlConnectionString` | Connection string SQL con Managed Identity | `Server=tcp:...;Authentication=Active Directory Managed Identity;...` |

**Acceder a secretos**:

```bash
# Listar secretos
az keyvault secret list \
  --vault-name kv-kitten-missions-dev-7bt5ye \
  --query "[].name" -o tsv

# Obtener valor de secret
az keyvault secret show \
  --vault-name kv-kitten-missions-dev-7bt5ye \
  --name SqlConnectionString \
  --query value -o tsv
```

---

## 🔄 Post-Deployment

### 1. Verificar Recursos Creados

```bash
# Listar todos los recursos en el RG
az resource list \
  --resource-group rg-kitten-missions-dev \
  --query "[].{Name:name, Type:type, Location:location}" \
  -o table
```

**Debe mostrar ~8-10 recursos**:
- App Service Plan
- App Service
- SQL Server
- SQL Database
- Key Vault
- Log Analytics Workspace
- Application Insights
- (+ diagnostic settings, firewall rules)

### 2. Configurar Firewall IPs del App Service

⚠️ **IMPORTANTE**: Por limitaciones de Bicep, las IPs salientes del App Service no pueden agregarse automáticamente al SQL Firewall. Debes hacerlo manualmente:

```bash
# 1. Obtener IPs salientes del App Service
OUTBOUND_IPS=$(az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query outboundIpAddresses -o tsv)

echo "App Service Outbound IPs: $OUTBOUND_IPS"

# 2. Agregar cada IP al SQL Firewall
IFS=',' read -ra IPS <<< "$OUTBOUND_IPS"
for i in "${!IPS[@]}"; do
  IP="${IPS[$i]}"
  az sql server firewall-rule create \
    --server sql-kitten-missions-dev-7bt5ye \
    --resource-group rg-kitten-missions-dev \
    --name "AllowAppService-IP$i" \
    --start-ip-address "$IP" \
    --end-ip-address "$IP"
  echo "✅ Added firewall rule for IP: $IP"
done
```

**Alternativa (Azure Portal)**:
1. Ve a SQL Server → Networking → Firewall rules
2. Copia las IPs de `outboundIpAddresses` del App Service
3. Añade reglas manualmente

### 3. Verificar Conectividad SQL

```bash
# Probar conexión SQL con Azure AD auth
az sql db show-connection-string \
  --server sql-kitten-missions-dev-7bt5ye \
  --name sqldb-kitten-missions-dev \
  --client ado.net \
  --auth-type ADIntegrated
```

### 4. Verificar Application Insights

```bash
# Obtener Instrumentation Key
az monitor app-insights component show \
  --app appi-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query instrumentationKey -o tsv
```

### 5. Configurar App Settings (Opcional)

Si necesitas agregar más app settings después del deploy:

```bash
az webapp config appsettings set \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --settings KEY1=value1 KEY2=value2
```

### 6. Habilitar Deployment Slot (Prod)

Para prod, habilita deployment slots para zero-downtime deployments:

```bash
# Crear staging slot
az webapp deployment slot create \
  --name app-kitten-missions-prod \
  --resource-group rg-kitten-missions-prod \
  --slot staging

# Después del deploy a staging, swap:
az webapp deployment slot swap \
  --name app-kitten-missions-prod \
  --resource-group rg-kitten-missions-prod \
  --slot staging \
  --target-slot production
```

---

## 🐛 Troubleshooting

### Error: "Az bicep command not found"

**Causa**: Azure CLI no instalado o versión antigua.

**Solución**:
```bash
# Instalar/actualizar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar versión (debe ser >= 2.20.0)
az --version
```

### Error: "The target scope 'resourceGroup' does not match..."

**Causa**: Intentando hacer deployment de subscription cuando el scope es resourceGroup.

**Solución**: Usa `az deployment group` en lugar de `az deployment sub`:

```bash
# ❌ Incorrecto
az deployment sub what-if --location westeurope --template-file main.bicep

# ✅ Correcto
az deployment group what-if --resource-group rg-kitten-missions-dev --template-file main.bicep
```

### Error: "The following arguments are required: --resource-group/-g"

**Causa**: Falta especificar el resource group.

**Solución**:
```bash
az deployment group what-if \
  --resource-group rg-kitten-missions-dev \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json
```

### Error: BCP037 "The property 'X' is not allowed on objects of type 'params'"

**Causa**: El parámetro referenciado no existe en el módulo.

**Solución**: Verifica que el parámetro existe en el módulo y coincide el nombre exacto.

### Error: "SQL Server name already exists"

**Causa**: El SQL Server name es global y ya está en uso.

**Solución**: El `uniqueString()` debería prevenir esto, pero si ocurre:

```bash
# Cambiar el projectName o eliminar el server existente
az sql server delete --name sql-kitten-missions-dev-7bt5ye --resource-group OLD-RG
```

### Error: "Cannot perform write operation because database is read-only"

**Causa**: SQL Database está en modo read-only (puede ocurrir tras fallos de backup).

**Solución**:
```bash
# Verificar estado
az sql db show \
  --name sqldb-kitten-missions-dev \
  --server sql-kitten-missions-dev-7bt5ye \
  --resource-group rg-kitten-missions-dev \
  --query status

# Si está en read-only, contacta soporte de Azure
```

### Warning: "Nested deployment short-circuited"

**Causa**: Bicep no puede evaluar completamente un módulo porque usa referencias dinámicas (como `managedIdentityPrincipalId`).

**Solución**: **Esto es NORMAL** y no indica error. El what-if simplemente no puede pre-calcular algunos valores. El deployment real funcionará correctamente.

### Error: "Location cannot be null"

**Causa**: Falta el parámetro location en dev.parameters.json.

**Solución**: Agrega location a los parámetros:

```json
{
  "location": {
    "value": "westeurope"
  }
}
```

### Error: "Key Vault name is not available"

**Causa**: El nombre del Key Vault está en soft-delete state.

**Solución**:
```bash
# Listar Key Vaults en soft-delete
az keyvault list-deleted --query "[].name" -o tsv

# Purge permanentemente (cuidado en prod)
az keyvault purge --name kv-kitten-missions-dev-7bt5ye
```

### Deployment Lento (>10 minutos)

**Causas comunes**:
- SQL Database creation (puede tardar 3-5 min)
- Diagnostic settings configuration
- Private Endpoints DNS propagation

**Solución**: Paciencia 😊. Si tarda >15 minutos, verifica logs:

```bash
# Ver actividad del deployment
az deployment group show \
  --resource-group rg-kitten-missions-dev \
  --name <DEPLOYMENT-NAME> \
  --query properties.error
```

---

## 🔒 Seguridad y Compliance

### Checklist de Seguridad

- ✅ **Managed Identities**: App Service usa managed identity (no passwords)
- ✅ **Azure AD Auth Only**: SQL Server con `azureADOnlyAuthentication: true`
- ✅ **TLS 1.2+**: Enforced en App Service y SQL Server
- ✅ **HTTPS Only**: App Service solo acepta HTTPS
- ✅ **Secrets en Key Vault**: SQL connection string almacenado en KV
- ✅ **Encryption at Rest**: TDE habilitado en SQL Database
- ✅ **Audit Logging**: Diagnostic settings en todos los recursos
- ✅ **Network Security**: SQL Firewall rules restrictivos
- ✅ **Soft Delete**: Key Vault con soft delete (7 días)

### Recomendaciones para Producción

Para entorno de producción, considera:

1. **Private Endpoints**: Eliminar acceso público a SQL Server
2. **VNet Integration**: Aislar App Service en VNet
3. **Azure Firewall**: Controlar egress del App Service
4. **Key Vault Purge Protection**: Habilitar para prevenir eliminación accidental
5. **Geo-Replication**: SQL Database con geo-redundancy
6. **Backup Policies**: Retention >30 días
7. **Azure Policy**: Enforced compliance rules
8. **Monitoring Alerts**: Configurar alertas críticas (5xx errors, high latency)

### Compliance Tags

Todos los recursos incluyen tags para compliance:

```bicep
tags: {
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Project: 'kitten-missions'
  CostCenter: 'Engineering'
  DataClassification: 'Internal'  // Agregar según tu org
  Compliance: 'GDPR'  // Agregar según requisitos
}
```

---

## 📚 Referencias

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure Naming Conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Bicep Module Registry](https://github.com/Azure/bicep-registry-modules)

---

## 🤝 Contribución

Para modificar la infraestructura:

1. **Crear branch**: `git checkout -b feature/new-module`
2. **Modificar Bicep**: Edita módulos en `modules/`
3. **Validar**: `az bicep build --file main.bicep`
4. **What-If**: Ejecutar what-if en dev
5. **PR Review**: Crear PR con descripción de cambios
6. **Deploy**: Después de aprobación, deploy a dev → test → prod

---

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/tu-org/azure-agent-pro/issues)
- **Documentación**: [Wiki del Proyecto](https://github.com/tu-org/azure-agent-pro/wiki)
- **Azure Support**: [Azure Portal Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

---

**🎉 ¡Infraestructura lista para desplegar!**

Próximo paso: [Actividad 5 - CI/CD con GitHub Actions](../../activity-05-cicd-setup.md)
