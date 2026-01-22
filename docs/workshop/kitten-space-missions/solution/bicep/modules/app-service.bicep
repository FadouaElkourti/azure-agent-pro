// Modern App Service module for Kitten Space Missions
// Updated with 2025 best practices and latest API version

metadata author = 'Azure_Architect_Pro'
metadata version = '1.0.0'
metadata description = 'Creates App Service Plan and App Service with modern security and configuration for Kitten Space Missions API'

// User-Defined Types for enhanced validation
@export()
type AppServiceSkuType = {
  @description('SKU name (F1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3)')
  name: string

  @description('SKU tier')
  tier: string

  @description('Number of workers (instances)')
  @minValue(1)
  @maxValue(10)
  capacity: int
}

@export()
type AutoScaleSettingsType = {
  @description('Enable auto-scaling')
  enabled: bool

  @description('Minimum number of instances')
  @minValue(1)
  @maxValue(10)
  minCapacity: int

  @description('Maximum number of instances')
  @minValue(1)
  @maxValue(10)
  maxCapacity: int
}

// Parameters with modern decorators
@description('App Service Plan name')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('App Service name')
@minLength(2)
@maxLength(60)
param appServiceName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('App Service Plan SKU configuration')
param sku AppServiceSkuType = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

@description('Operating system type')
@allowed(['Linux', 'Windows'])
param operatingSystem string = 'Linux'

@description('Runtime stack for the application')
@allowed([
  'DOTNET|8.0'
  'DOTNET|7.0'
  'DOTNET|6.0'
  'NODE|20-lts'
  'NODE|18-lts'
  'PYTHON|3.11'
  'PYTHON|3.10'
  'PYTHON|3.9'
])
param runtimeStack string = 'DOTNET|8.0'

@description('Enable Always On (requires Basic tier or higher)')
param alwaysOn bool = true

@description('Enable HTTPS only')
param httpsOnly bool = true

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2', '1.3'])
param minTlsVersion string = '1.2'

@description('Enable HTTP/2')
param http20Enabled bool = true

@description('Enable FTP for deployments')
@allowed(['AllAllowed', 'FtpsOnly', 'Disabled'])
param ftpsState string = 'Disabled'

@description('Enable auto-scaling configuration')
param autoScaleSettings AutoScaleSettingsType = {
  enabled: true
  minCapacity: 1
  maxCapacity: 3
}

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string = ''

@description('Application Insights instrumentation key')
@secure()
param appInsightsInstrumentationKey string = ''

@description('Enable managed identity')
param enableManagedIdentity bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags for organization and governance')
param tags object = {
  Environment: 'dev'
  Project: 'kitten-space-missions'
  CreatedBy: 'bicep-template'
  ManagedBy: 'Azure-Agent-Pro'
}

// Variables
var isLinux = operatingSystem == 'Linux'
var appServiceKind = isLinux ? 'app,linux' : 'app'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: union(tags, {
    resource: 'app-service-plan'
    deployedBy: 'Bicep'
  })
  sku: {
    name: sku.name
    tier: sku.tier
    capacity: sku.capacity
  }
  kind: isLinux ? 'linux' : ''
  properties: {
    reserved: isLinux
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: union(tags, {
    resource: 'app-service'
    deployedBy: 'Bicep'
  })
  kind: appServiceKind
  identity: enableManagedIdentity
    ? {
        type: 'SystemAssigned'
      }
    : null
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: isLinux ? runtimeStack : null
      windowsFxVersion: !isLinux ? runtimeStack : null
      alwaysOn: alwaysOn
      http20Enabled: http20Enabled
      minTlsVersion: minTlsVersion
      ftpsState: ftpsState
      healthCheckPath: '/health'
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      remoteDebuggingEnabled: false
      scmMinTlsVersion: minTlsVersion
      use32BitWorkerProcess: false
      webSocketsEnabled: false
      managedPipelineMode: 'Integrated'
      loadBalancing: 'LeastRequests'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
      // Note: customAppSettings parameter removed to simplify deployment
      // Add custom settings via Azure Portal or separate deployment
    }
  }
}

// Auto-scaling rules (only if enabled and not Free/Shared tier)
resource appServiceAutoScale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (autoScaleSettings.enabled && sku.name != 'F1' && sku.name != 'D1') {
  name: '${appServicePlanName}-autoscale'
  location: location
  tags: tags
  properties: {
    enabled: true
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: 'Auto scale condition'
        capacity: {
          minimum: string(autoScaleSettings.minCapacity)
          maximum: string(autoScaleSettings.maxCapacity)
          default: string(autoScaleSettings.minCapacity)
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'MemoryPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

// Diagnostic settings for App Service
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${appService.name}-diagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
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

// Outputs
@description('App Service Plan resource ID')
output appServicePlanId string = appServicePlan.id

@description('App Service Plan name')
output appServicePlanName string = appServicePlan.name

@description('App Service resource ID')
output appServiceId string = appService.id

@description('App Service name')
output appServiceName string = appService.name

@description('App Service default hostname')
output appServiceHostName string = appService.properties.defaultHostName

@description('App Service outbound IP addresses')
output outboundIpAddresses string = appService.properties.outboundIpAddresses

@description('App Service possible outbound IP addresses')
output possibleOutboundIpAddresses string = appService.properties.possibleOutboundIpAddresses

@description('Managed Identity Principal ID (if enabled)')
output managedIdentityPrincipalId string = enableManagedIdentity ? appService.identity.principalId : ''

@description('Managed Identity Tenant ID (if enabled)')
output managedIdentityTenantId string = enableManagedIdentity ? appService.identity.tenantId : ''
