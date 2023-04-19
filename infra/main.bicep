targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param apiContainerAppName string = ''
param apiImageName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param storageShare string = 'storageshare'
@secure()
param bearerToken string
param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param datastore string = 'redis'
param logAnalyticsName string = ''
@secure()
param openAiApiKey string
param redisContainerAppName string = ''
param redisContainerPort int = 80
param redisHost string = ''
param redisImageName string = ''
@secure()
param redisPassword string = ''
param redisPort int = 6379
param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module storageAccount './core/storage/storage-account.bicep' = {
  name: 'storage-account'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    kind: 'FileStorage'
    sku: {
      name: 'Premium_LRS'
    }
    shares: [
      {
        name: storageShare
        accessTier: 'Premium'
        enabledProtocols: 'SMB'
      }
    ]
  }
}

// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: rg
  params: {
    name: 'app'
    containerAppsEnvironmentName: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    tags: tags
    storage: {
      storageAccountName: storageAccount.outputs.name
      share: storageShare
    }
  }
}

// api frontend
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiContainerAppName) ? apiContainerAppName : '${abbrs.appContainerApps}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    bearerToken: bearerToken
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    datastore: datastore
    imageName: apiImageName
    openAiApiKey: openAiApiKey
    redisContainerPort: redisContainerPort
    redisHost: !empty(redisHost) ? redisHost : redis.outputs.SERVICE_REDIS_NAME
    redisPassword: redisPassword
    redisPort: redisPort
  }
}

module redis './app/redis.bicep' = {
  name: 'redis'
  scope: rg
  params: {
    name: !empty(redisContainerAppName) ? redisContainerAppName : '${abbrs.appContainerApps}redis-${resourceToken}'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    imageName: redisImageName
    redisPort: redisPort
    storageName: containerApps.outputs.environmentStorage
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output AZURE_LOCATION string = location
output AZURE_LOG_ANALYTICS_NAME string = monitoring.outputs.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_TENANT_ID string = tenant().tenantId
output SERVICE_API_URI string = api.outputs.SERVICE_API_URI
output SERVICE_API_NAME string = api.outputs.SERVICE_API_NAME
output SERVICE_API_IMAGE_NAME string = api.outputs.SERVICE_API_IMAGE_NAME
output SERVICE_REDIS_NAME string = redis.outputs.SERVICE_REDIS_NAME
output SERVICE_REDIS_IMAGE_NAME string = redis.outputs.SERVICE_REDIS_IMAGE_NAME
output REDIS_CONTAINER_PORT int = redisContainerPort
output REDIS_HOST string = redis.outputs.SERVICE_REDIS_NAME
output REDIS_PORT int = redisPort
output DATASTORE string = datastore
output PLUGIN_HOSTNAME string = api.outputs.SERVICE_API_URI
