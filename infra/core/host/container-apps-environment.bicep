param name string
param location string = resourceGroup().location
param tags object = {}
param storage object = {}

param logAnalyticsWorkspaceName string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }

  resource azureFilesStorage 'storages' = if (!empty(storage)) {
    name: 'azurefilesstorage'
    properties: {
      azureFile: {
        accountName: storageAccount.name
        shareName: storageAccount::fileService::fileShare.name
        accessMode: 'ReadWrite'
        accountKey: storageAccount.listKeys().keys[0].value
      }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (!empty(storage)) {
  name: storage.storageAccountName
  resource fileService 'fileServices' existing = {
    name: 'default'
    resource fileShare 'shares' existing = {
      name: storage.share
    }
  }
}

output name string = containerAppsEnvironment.name
output storageName string = containerAppsEnvironment::azureFilesStorage.name
