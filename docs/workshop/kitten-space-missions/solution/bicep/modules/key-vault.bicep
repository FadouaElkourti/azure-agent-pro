// Key Vault module for Kitten Space Missions API
// Stores secrets and connection strings securely

metadata author = 'Azure_Architect_Pro'
metadata version = '1.0.0'
metadata description = 'Creates Azure Key Vault with access policies for App Service Managed Identity'

// ========================================
// PARAMETERS
// ========================================

@description('Key Vault name (must be globally unique)')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('App Service Managed Identity Principal ID for access policy')
param appServicePrincipalId string

@description('Azure AD tenant ID')
param tenantId string = subscription().tenantId

@description('Enable soft delete (recommended for production)')
param enableSoftDelete bool = true

@description('Soft delete retention days (7-90 days)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7

@description('Enable purge protection (prevents permanent deletion)')
param enablePurgeProtection bool = true // Default true - cannot be disabled once enabled

@description('SKU name for Key Vault')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Common resource tags')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

// ========================================
// RESOURCES
// ========================================

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId

    // Modern access policy model (not RBAC for secrets compatibility)
    enableRbacAuthorization: false

    accessPolicies: [
      {
        tenantId: tenantId
        objectId: appServicePrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          keys: []
          certificates: []
        }
      }
    ]

    // Security settings
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection

    // Network settings (allow Azure services for dev)
    networkAcls: {
      defaultAction: 'Allow' // For dev - change to 'Deny' in prod with Private Endpoint
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }

    // Public access settings
    publicNetworkAccess: 'Enabled' // For dev - set to 'Disabled' in prod
  }
}

// Diagnostic settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
  }
}

// ========================================
// OUTPUTS
// ========================================

@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault resource for creating secrets')
output keyVaultResource object = {
  id: keyVault.id
  name: keyVault.name
  uri: keyVault.properties.vaultUri
}
