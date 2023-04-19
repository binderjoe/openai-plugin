param name string
param location string = resourceGroup().location
param tags object = {}

@description('Specify the pricing tier of the new Azure Redis Cache.')
@allowed([
  'EnterpriseFlash_F1500'
  'EnterpriseFlash_F300'
  'EnterpriseFlash_F700'
  'Enterprise_E10'
  'Enterprise_E100'
  'Enterprise_E20'
  'Enterprise_E50'
])
param skuName string = 'Enterprise_E10'

@description('Specify the size of the new Azure Redis Cache instance. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4)')
@allowed([
  0
  1
  2
  3
  4
  5
  6
])
param skuCapacity int = contains(skuName, 'Flash') ? 3 : 2

param zones array = []

@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimumTlsVersion string = '1.2'

resource redis 'Microsoft.Cache/redisEnterprise@2023-03-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    capacity: skuCapacity
    name: skuName
  }
  properties: {
    minimumTlsVersion: minimumTlsVersion
  }
  zones: zones
}

output endpoint string = redis.properties.hostName
output id string = redis.id
output name string = redis.name
output port int = redis.properties.port
output sslPort int = redis.properties.sslPort
