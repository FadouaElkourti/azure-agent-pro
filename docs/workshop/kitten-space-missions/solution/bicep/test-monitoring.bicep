// Test deployment for monitoring module only
targetScope = 'resourceGroup'

param projectName string = 'kitten-missions'
param environment string = 'dev'
param location string = 'northeurope'

var resourceNames = {
  logAnalytics: 'log-${projectName}-${environment}'
  appInsights: 'appi-${projectName}-${environment}'
}

module monitoring './modules/monitoring.bicep' = {
  name: 'deploy-monitoring-test'
  params: {
    logAnalyticsWorkspaceName: resourceNames.logAnalytics
    applicationInsightsName: resourceNames.appInsights
    location: location
    logAnalyticsSku: 'PerGB2018'
    retentionInDays: 30
    applicationType: 'web'
    samplingPercentage: 50
    tags: {
      Environment: environment
      Project: projectName
    }
  }
}

output logAnalyticsId string = monitoring.outputs.logAnalyticsWorkspaceId
output appInsightsId string = monitoring.outputs.applicationInsightsId
