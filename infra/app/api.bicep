param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
@secure()
param bearerToken string
param containerAppsEnvironmentName string
param containerRegistryName string
param datastore string = 'redis'
param imageName string = ''
@secure()
param openAiApiKey string = ''
param serviceName string = 'api'
param redisContainerPort int = 80
param redisHost string = ''
@secure()
param redisPassword string = ''
param redisPort int = 6379

module app '../core/host/container-app.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
      {
        name: 'BEARER_TOKEN'
        value: bearerToken
      }
      {
        name: 'DATASTORE'
        value: datastore
      }
      {
        name: 'OPENAI_API_KEY'
        value: openAiApiKey
      }
      {
        name: 'PORT'
        value: string(redisContainerPort)
      }
      {
        name: 'REDIS_HOST'
        value: redisHost
      }
      {
        name: 'REDIS_PASSWORD'
        value: redisPassword
      }
      {
        name: 'REDIS_PORT'
        value: string(redisPort)
      }
      {
        name: 'PLUGIN_HOSTNAME'
        value: 'https://${name}.${containerAppsEnvironment.properties.defaultDomain}'
      }
    ]
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    targetPort: 80
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = app.outputs.identityPrincipalId
output SERVICE_API_IMAGE_NAME string = app.outputs.imageName
output SERVICE_API_NAME string = app.outputs.name
output SERVICE_API_URI string = app.outputs.uri
