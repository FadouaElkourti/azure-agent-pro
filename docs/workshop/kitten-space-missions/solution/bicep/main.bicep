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
// MODULE: APP SERVICE (Deploy first to get outbound IPs)
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
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    enableManagedIdentity: true
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: commonTags
  }
}

// ========================================
// MODULE: KEY VAULT
// ========================================

module keyVault './modules/key-vault.bicep' = {
  name: 'deploy-keyvault-${uniqueString(deployment().name)}'
  params: {
    keyVaultName: resourceNames.keyVault
    location: location
    appServicePrincipalId: appService.outputs.managedIdentityPrincipalId
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7 // Minimum for dev
    enablePurgeProtection: false // Allow purge in dev for testing
    skuName: 'standard' // Standard tier for dev
    tags: commonTags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// ========================================
// MODULE: SQL DATABASE
// ========================================

module sqlDatabase './modules/sql-database.bicep' = {
  name: 'deploy-sql-${uniqueString(deployment().name)}'
  params: {
    sqlServerName: resourceNames.sqlServer
    sqlDatabaseName: resourceNames.sqlDatabase
    location: location
    azureAdAdminObjectId: sqlAzureAdAdminObjectId
    azureAdAdminUsername: sqlAzureAdAdminUsername
    tenantId: subscription().tenantId
    databaseSku: 'Basic' // Cost-optimized for dev
    maxSizeBytes: 2147483648 // 2GB for Basic tier
    zoneRedundant: false
    publicNetworkAccess: true // For dev - use false with Private Endpoint in prod
    tags: commonTags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// ========================================
// SQL FIREWALL RULES (Allow Azure services + App Service IPs)
// ========================================

// Allow Azure services to access SQL Server
resource sqlFirewallAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  name: '${resourceNames.sqlServer}/AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlDatabase
  ]
}

// NOTE: App Service outbound IPs should be added manually or via Azure Portal
// Dynamic firewall rules based on runtime values cannot be deployed in Bicep
// See: docs/workshop/kitten-space-missions/solution/docs/POST-DEPLOYMENT.md

// ========================================
// KEY VAULT SECRETS
// ========================================

// SQL Connection String (stored as Key Vault secret)
resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${resourceNames.keyVault}/SqlConnectionString'
  properties: {
    value: 'Server=tcp:${sqlDatabase.outputs.sqlServerFqdn},1433;Database=${sqlDatabase.outputs.sqlDatabaseName};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
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
output sqlServerName string = sqlDatabase.outputs.sqlServerName

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.outputs.sqlDatabaseName

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn

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

@description('App Service outbound IP addresses (add these to SQL firewall manually)')
output appServiceOutboundIps string = appService.outputs.outboundIpAddresses
