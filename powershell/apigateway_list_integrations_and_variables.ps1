# This is a Powershell script to gather information on APIs from AWS API Gateway
# Created and maintained by: Willer Pulis
# If you are using AWS CloudShell, enter the Powershell environment by running the command "pwsh"
# Then run the two following commands:
# Install-Module AWSPowerShell
# Import-Module AWSPowerShell

# Getting date
$date=Get-Date -Format yyyy-MM-dd

# Looping through all APIs
foreach ($api in Get-AGRestApiList) {
    
    # Looping through each resource
    foreach ($apiResource in (Get-AGResourceList -RestApiId $api.Id)){

        $resourcesObj = New-Object -Type PSObject
        $resourcesObj = @()

        # Looping through each method
        foreach ($apiResourceMethod in $apiResource.ResourceMethods.Keys){

            # Getting the method integration
            $apiResourceMethodIntegration = Get-AGIntegration -RestApiId $api.Id -ResourceId $apiResource.Id -HttpMethod $apiResourceMethod
            # Creating a custom PowerShell object with relevant data
            $resourceObj = New-Object -Type PSObject -Property @{
                'apiId' = $api.Id
                'apiName' = $api.Name
                'apiType' = $api.EndpointConfiguration.Types[0]
                'resourceId' = $apiResource.Id
                'resourcePath' = $apiResource.Path
                'httpMethod' = $apiResourceMethod
                'methodIntegrationType' = $apiResourceMethodIntegration.Type
                'methodIntegrationUri' = $apiResourceMethodIntegration.Uri
            }
            $resourcesObj += $resourceObj
        }

        # Exporting to CSV file
        $resourcesObj | select apiId,apiName,apiType,resourceId,resourcePath,httpMethod,methodIntegrationType,methodIntegrationUri `
        | Export-Csv -Path "$($date)_apigw_resource_method_integrations.csv" -Encoding ascii -NoTypeInformation -Append -Force
    }
    
    
    # Looping through each stage
    foreach ($apiStage in (Get-AGStageList -RestApiId $api.Id)){

        $variablesObj = New-Object -Type PSObject
        $variablesObj = @()

        # Looping through each variable
        foreach ($apiStageVarKey in $apiStage.Variables.Keys) {
            # Creating a custom PowerShell object with relevant data
            $variableObj = New-Object -Type PSObject -Property @{
                'apiId' = $api.Id
                'apiName' = $api.Name
                'apiType' = $api.EndpointConfiguration.Types[0]
                'stageName' = $apiStage.StageName
                'stageVariableName' = $apiStageVarKey
                'stageVariableValue' = $apiStage.Variables[$apiStageVarKey]
            }
            $variablesObj += $variableObj
        }

        # Exporting to CSV file
        $variablesObj | select apiId,apiName,apiType,stageName,stageVariableName,stageVariableValue `
        | Export-Csv -Path "$($date)_apigw_stage_variables.csv" -Encoding ascii -NoTypeInformation -Append -Force
    }
}

