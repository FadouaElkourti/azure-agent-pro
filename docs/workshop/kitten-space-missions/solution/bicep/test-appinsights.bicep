// Test deployment for Application Insights only
targetScope = 'resourceGroup'

param projectName string = 'kitten-missions'
param environment string = 'dev'
param location string = 'northeurope'

// Reference existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-${projectName}-${environment}'
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}'
  location: location
  kind: 'web'
  tags: {
    Environment: environment
    Project: projectName
    resource: 'application-insights'
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableIpMasking: false
    SamplingPercentage: 50
    RetentionInDays: 30
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

output appInsightsId string = applicationInsights.id
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output connectionString string = applicationInsights.properties.ConnectionString
