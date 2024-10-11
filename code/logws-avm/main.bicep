@description('Required. Name of the workspace.')
param name string = 'siem'

@description('Optional. Number of days data will be retained for.')
param dataRetention int = 90

@description('Optional. Daily quota in GB.')
param dailyQuotaGb int = 100

@description('Required per policy. Tags of the resource.')
param tags object = {
  Environment: 'dev'
}
@description('Optional. location.')
param location string = 'swedencentral'

@description('optional. storagename.')
param storageName string = 'dummysto1234'

module storage 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: '${uniqueString(deployment().name)}-storageacc'
  params: {
    // Required parameters
    // this code will generate a unique 3-letter string based on the name of the deployment and append it to the end of the storage account name. Note that the substring() function takes three parameters: the string to take a subset of, the start index, and the length of the subset. In this case, it starts at the beginning of the string (index 0) and takes the first 3 characters.
    //name: 'loggingstorage${substring(uniqueString(deployment().name), 0, 3)}' 
    name: storageName
    // Non-required parameters
    allowBlobPublicAccess: false
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: '${uniqueString(deployment().name)}-avm-logws'
  params: {
    // Required parameters
    name: name
    // Non-required parameters
    location: location
    skuName: 'PerGB2018'
    dailyQuotaGb: dailyQuotaGb
    dataRetention: dataRetention
    tags: tags
    useResourcePermissions: true
    gallerySolutions: [
      {
        name: 'SecurityInsights'
        plan: {
          name: 'SecurityInsights()'
          publisher: 'Microsoft'
          product: 'OMSGallery/SecurityInsights'
          promotionCode: ''
        }
      }
    ]
    dataExports: [
      {
        destination: {
          resourceId: storage.outputs.resourceId
        }
        enable: true
        name: 'storageAccountExport'
        tableNames: [
          'AzureActivity'
        ]
      }
    ]
  }
}
