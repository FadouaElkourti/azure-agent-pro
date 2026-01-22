// Main Bicep template for Kitten Space Missions API
// Orchestrates all infrastructure modules following azure-agent-pro conventions
// Author: Azure_Architect_Pro
// Date: 2026-01-22

metadata author = 'Azure_Architect_Pro'
metadata version = '1.0.0'
metadata description = 'Main orchestrator for Kitten Space Missions API infrastructure'

// ========================================
// PARAMETERS
// ========================================

@description('Project name prefix for resource naming')
param projectName string = 'kitten-missions'

@description('Environment designation')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Azure AD admin object ID for SQL Database')
param sqlAzureAdAdminObjectId string

@description('Azure AD admin username for SQL Database')
param sqlAzureAdAdminUsername string

// ========================================
// VARIABLES
// ========================================

var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 6)

// Resource naming following azure-agent-pro conventions
var resourceNames = {
  appServicePlan: 'plan-${projectName}-${environment}'
  appService: 'app-${projectName}-${environment}'
  sqlServer: 'sql-${projectName}-${environment}-${uniqueSuffix}'
  sqlDatabase: 'sqldb-${projectName}-${environment}'
  keyVault: 'kv-${projectName}-${environment}-${uniqueSuffix}'
  logAnalytics: 'log-${projectName}-${environment}'
  appInsights: 'appi-${projectName}-${environment}'
}

// Common tags following azure-agent-pro conventions
var commonTags = {
  Environment: environment
  Project: projectName
  CreatedBy: 'bicep-template'
  CreatedDate: '2026-01-22'
  ManagedBy: 'Azure-Agent-Pro'
  Purpose: 'kitten-space-missions-api'
}

// SQL Database firewall allowed IPs (empty for now, will be populated with App Service IPs)
var sqlAllowedIps = []

// ========================================
// MODULE: MONITORING (Log Analytics + Application Insights)
// ========================================

module monitoring './modules/monitoring.bicep' = {
  name: 'deploy-monitoring-${uniqueString(deployment().name)}'
  params: {
    logAnalyticsWorkspaceName: resourceNames.logAnalytics
    applicationInsightsName: resourceNames.appInsights
    location: location
    logAnalyticsSku: 'PerGB2018'
    retentionInDays: 7 // Cost-optimized for dev
    applicationType: 'web'
    samplingPercentage: 50 // 50% sampling for dev cost optimization
    tags: commonTags
  }
}

// ========================================
// MODULE: KEY VAULT
// ========================================

module keyVault '../../../../bicep/modules/key-vault.bicep' = {
  name: 'deploy-keyvault-${uniqueString(deployment().name)}'
  params: {
    keyVaultName: resourceNames.keyVault
    location: location
    sku: 'standard' // Standard tier for dev
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7 // Minimum for dev
    enablePurgeProtection: false // Allow purge in dev for testing
    publicNetworkAccess: 'enabled' // Public access for dev (change to 'disabled' for prod)
    networkAclsDefaultAction: 'Allow' // Allow all for dev simplicity
    tags: commonTags
  }
}

// ========================================
// MODULE: SQL DATABASE
// ========================================

module sqlDatabase '../../../../bicep/modules/sql-database.bicep' = {
  name: 'deploy-sql-${uniqueString(deployment().name)}'
  params: {
    sqlServerName: resourceNames.sqlServer
    location: location
    databaseName: resourceNames.sqlDatabase
    databaseSku: 'Basic' // Cost-optimized for dev
    enableAzureADAuth: true
    azureAdAdminObjectId: sqlAzureAdAdminObjectId
    azureAdAdminUsername: sqlAzureAdAdminUsername
    enableTDE: true
    enableThreatProtection: false // Disabled for dev cost optimization
    enableAuditing: true
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enablePrivateEndpoint: false // No Private Endpoint for dev (cost optimization)
    backupRetentionDays: 7 // Minimum for dev
    enableGeoRedundantBackup: false // No geo-redundancy for dev
    allowedIpAddresses: sqlAllowedIps
    tags: commonTags
  }
}

// ========================================
// MODULE: APP SERVICE
// ========================================

module appService './modules/app-service.bicep' = {
  name: 'deploy-appservice-${uniqueString(deployment().name)}'
  params: {
    appServicePlanName: resourceNames.appServicePlan
    appServiceName: resourceNames.appService
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
    operatingSystem: 'Linux'
    runtimeStack: 'DOTNET|8.0'
    alwaysOn: true // Always On enabled (B1 feature)
    httpsOnly: true
    minTlsVersion: '1.2'
    http20Enabled: true
    ftpsState: 'Disabled'
    autoScaleSettings: {
      enabled: true
      minCapacity: 1
      maxCapacity: 3
    }
    keyVaultName: resourceNames.keyVault
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    customAppSettings: {
      ASPNETCORE_ENVIRONMENT: environment == 'dev' ? 'Development' : 'Production'
      PROJECT_NAME: projectName
      SQL_DATABASE_NAME: resourceNames.sqlDatabase
      SQL_SERVER_NAME: '${resourceNames.sqlServer}.database.windows.net'
    }
    enableManagedIdentity: true
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: commonTags
  }
}

// ========================================
// SQL FIREWALL RULES (Dynamic - based on App Service outbound IPs)
// ========================================

// Parse App Service outbound IPs
var appServiceOutboundIps = split(appService.outputs.outboundIpAddresses, ',')

// Create firewall rule for each App Service outbound IP
resource sqlFirewallRules 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = [
  for (ip, index) in appServiceOutboundIps: {
    name: '${resourceNames.sqlServer}/AllowAppService-${index}'
    properties: {
      startIpAddress: trim(ip)
      endIpAddress: trim(ip)
    }
    dependsOn: [
      sqlDatabase
      appService
    ]
  }
]

// ========================================
// RBAC: App Service Managed Identity → Key Vault
// ========================================

// Key Vault Secrets User role definition ID
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.outputs.keyVaultId, appService.outputs.managedIdentityPrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: appService.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ========================================
// KEY VAULT SECRETS
// ========================================

// SQL Connection String (stored as Key Vault secret)
resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  name: '${resourceNames.keyVault}/SqlConnectionString'
  properties: {
    value: 'Server=tcp:${resourceNames.sqlServer}.database.windows.net,1433;Database=${resourceNames.sqlDatabase};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
  dependsOn: [
    keyVault
    sqlDatabase
  ]
}

// ========================================
// OUTPUTS
// ========================================

@description('Resource Group name')
output resourceGroupName string = resourceGroup().name

@description('App Service name')
output appServiceName string = appService.outputs.appServiceName

@description('App Service URL')
output appServiceUrl string = 'https://${appService.outputs.appServiceHostName}'

@description('App Service Managed Identity Principal ID')
output appServiceManagedIdentityPrincipalId string = appService.outputs.managedIdentityPrincipalId

@description('SQL Server name')
output sqlServerName string = resourceNames.sqlServer

@description('SQL Database name')
output sqlDatabaseName string = resourceNames.sqlDatabase

@description('SQL Server FQDN')
output sqlServerFqdn string = '${resourceNames.sqlServer}.database.windows.net'

@description('Key Vault name')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.keyVaultUri

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = monitoring.outputs.applicationInsightsInstrumentationKey

@description('Application Insights Connection String')
output appInsightsConnectionString string = monitoring.outputs.applicationInsightsConnectionString

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId

@description('App Service outbound IP addresses')
output appServiceOutboundIps string = appService.outputs.outboundIpAddresses
