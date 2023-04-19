param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = ''
param serviceName string = 'redis'
param redisPort int = 6379
param storageName string = ''

module app '../core/host/container-app.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    imageName: !empty(imageName) ? imageName : 'redis/redis-stack-server:latest'
    targetPort: redisPort
    transport: 'tcp'
    external: false
    storage: {
      name: storageName
      // ref: ./examples/docker/redis/docker-compose.yml
      mountPath: '/data'
    }
  }
}

output SERVICE_REDIS_IDENTITY_PRINCIPAL_ID string = app.outputs.identityPrincipalId
output SERVICE_REDIS_IMAGE_NAME string = app.outputs.imageName
output SERVICE_REDIS_NAME string = app.outputs.name
output SERVICE_REDIS_URI string = app.outputs.uri
