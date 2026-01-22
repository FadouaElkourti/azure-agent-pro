// Modern Monitoring module for Kitten Space Missions
// Updated with 2025 best practices and latest API version

metadata author = 'Azure_Architect_Pro'
metadata version = '1.0.0'
metadata description = 'Creates Application Insights and Log Analytics Workspace with modern configuration'

// User-Defined Types for enhanced validation
@export()
type LogAnalyticsSkuType = 'Free' | 'PerGB2018' | 'PerNode' | 'Premium' | 'Standalone' | 'Standard'

@export()
type AppInsightsType = 'web' | 'other'

// Parameters with modern decorators
@description('Log Analytics Workspace name')
@minLength(4)
@maxLength(63)
param logAnalyticsWorkspaceName string

@description('Application Insights name')
@minLength(1)
@maxLength(255)
param applicationInsightsName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Log Analytics Workspace SKU')
param logAnalyticsSku LogAnalyticsSkuType = 'PerGB2018'

@description('Log Analytics data retention in days')
@minValue(7)
@maxValue(730)
param retentionInDays int = 7

@description('Application Insights type')
param applicationType AppInsightsType = 'web'

@description('Application Insights sampling percentage (0-100)')
@minValue(0)
@maxValue(100)
param samplingPercentage int = 50

@description('Enable Application Insights ingestion over public network')
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Enable Application Insights query over public network')
param publicNetworkAccessForQuery string = 'Enabled'

@description('Disable IP masking in Application Insights telemetry')
param disableIpMasking bool = false

@description('Resource tags for organization and governance')
param tags object = {
  Environment: 'dev'
  Project: 'kitten-space-missions'
  CreatedBy: 'bicep-template'
  ManagedBy: 'Azure-Agent-Pro'
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: union(tags, {
    resource: 'log-analytics-workspace'
    deployedBy: 'Bicep'
  })
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
      enableDataExport: false
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: applicationType
  tags: union(tags, {
    resource: 'application-insights'
    deployedBy: 'Bicep'
  })
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    DisableIpMasking: disableIpMasking
    SamplingPercentage: samplingPercentage
    RetentionInDays: retentionInDays
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

// Smart Detection: Slow page load time
resource slowPageLoadDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'slowpageloadtime'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'slowpageloadtime'
      DisplayName: 'Slow page load time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Smart Detection: Slow server response time
resource slowServerResponseDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'slowserverresponsetime'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'slowserverresponsetime'
      DisplayName: 'Slow server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Smart Detection: Degradation in server response time
resource degradationServerResponseDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'degradationinserverresponsetime'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'degradationinserverresponsetime'
      DisplayName: 'Degradation in server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Smart Detection: Long dependency duration
resource longDependencyDurationDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'longdependencyduration'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'longdependencyduration'
      DisplayName: 'Long dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Smart Detection: Degradation in dependency duration
resource degradationDependencyDurationDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'degradationindependencyduration'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'degradationindependencyduration'
      DisplayName: 'Degradation in dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Smart Detection: Abnormal rise in exception volume
resource exceptionVolumeDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: applicationInsights
  name: 'extension_exceptionchangeextension'
  properties: {
    enabled: true
    sendEmailsToSubscriptionOwners: false
    customEmails: []
    ruleDefinitions: {
      Name: 'extension_exceptionchangeextension'
      DisplayName: 'Abnormal rise in exception volume'
      Description: 'This detection rule automatically analyzes the exceptions thrown in your application, and can warn you about unusual patterns in your exception telemetry.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-exception-volume'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
  }
}

// Outputs
@description('Log Analytics Workspace resource ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace name')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics Workspace Customer ID')
output logAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('Application Insights resource ID')
output applicationInsightsId string = applicationInsights.id

@description('Application Insights name')
output applicationInsightsName string = applicationInsights.name

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('Application Insights Application ID')
output applicationInsightsAppId string = applicationInsights.properties.AppId
