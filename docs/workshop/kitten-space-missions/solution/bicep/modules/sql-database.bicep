// SQL Database module for Kitten Space Missions API
// Creates SQL Server and Database with Azure AD authentication

metadata author = 'Azure_Architect_Pro'
metadata version = '1.0.0'
metadata description = 'Creates Azure SQL Server and Database with Azure AD authentication only'

// ========================================
// PARAMETERS
// ========================================

@description('SQL Server name (must be globally unique)')
@minLength(1)
@maxLength(63)
param sqlServerName string

@description('SQL Database name')
@minLength(1)
@maxLength(128)
param sqlDatabaseName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Azure AD administrator object ID')
param azureAdAdminObjectId string

@description('Azure AD administrator username (email or UPN)')
param azureAdAdminUsername string

@description('Azure AD tenant ID')
param tenantId string = subscription().tenantId

@description('SQL Database SKU name')
@allowed(['Basic', 'S0', 'S1', 'S2', 'S3', 'P1', 'P2'])
param databaseSku string = 'Basic'

@description('Maximum database size in bytes (2GB for Basic)')
param maxSizeBytes int = 2147483648 // 2GB default

@description('Enable zone redundancy (not supported in Basic tier)')
param zoneRedundant bool = false

@description('Common resource tags')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('Enable public network access (set to false with Private Endpoint)')
param publicNetworkAccess bool = true

// ========================================
// VARIABLES
// ========================================

var sqlSkuMap = {
  Basic: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  S0: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  S1: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 20
  }
}

var selectedSku = sqlSkuMap[databaseSku]

// ========================================
// RESOURCES
// ========================================

// SQL Server (logical server)
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    // No SQL authentication - Azure AD only
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: azureAdAdminUsername
      sid: azureAdAdminObjectId
      tenantId: tenantId
      azureADOnlyAuthentication: true // Critical: AD only, no SQL auth
    }

    // Security settings
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'

    // Disable SQL authentication
    // NOTE: SQL admin login/password cannot be set when azureADOnlyAuthentication is true
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: selectedSku.name
    tier: selectedSku.tier
    capacity: selectedSku.capacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: maxSizeBytes
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: zoneRedundant

    // Backup and retention
    requestedBackupStorageRedundancy: 'Local' // For dev - use 'Geo' in prod
  }
}

// Transparent Data Encryption (enabled by default in Azure SQL)
resource tde 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-05-01-preview' = {
  parent: sqlDatabase
  name: 'current'
  properties: {
    state: 'Enabled'
  }
}

// Note: SQL Server diagnostic settings removed as SQLSecurityAuditEvents category is not supported
// Audit logs should be configured via SQL Server auditing settings instead

// Diagnostic settings for SQL Database
resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDatabaseName}-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ========================================
// OUTPUTS
// ========================================

@description('SQL Server resource ID')
output sqlServerId string = sqlServer.id

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Server fully qualified domain name')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Database resource ID')
output sqlDatabaseId string = sqlDatabase.id

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('Connection string template (requires @Microsoft.KeyVault reference in app)')
output connectionStringTemplate string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabaseName};Authentication=Active Directory Default;'
