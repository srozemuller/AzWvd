function Update-AvdDesktopApplication {
    <#
    .SYNOPSIS
    Updates the Virtual Desktop ApplicationGroup desktop application
    .DESCRIPTION
    The function will update the desktop application SessionDesktop with a friendlyname and/or displayname.
    .PARAMETER ApplicationGroupName
    Enter the AVD application group name
    .PARAMETER ResourceGroupName
    Enter the AVD application group resourcegroup name
    .PARAMETER ResourceId
    Enter the AVD application group resourceId
    .PARAMETER friendlyName
    Provide a displayname, this is the name you see in the webclient and Remote Desktop Client.
    .PARAMETER description
    Enter a description   
    .EXAMPLE
    Update-AvdDesktopApplication -ApplicationGroupName avd-applicationgroup -ResourceGroupName rg-avd-01 -DisplayName "Update Desktop"
    .EXAMPLE
    Update-AvdDesktopApplication -ResourceId "/subscriptions/../applicationName" -DisplayName "Update Desktop"
    #>
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param
    (
        [parameter(Mandatory, ParameterSetName="Name")]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationGroupName,
    
        [parameter(Mandatory, ParameterSetName="Name")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
    
        [parameter(Mandatory, ParameterSetName="ResourceId")]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceId,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$description,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$friendlyName
        
    )
    Begin {
        Write-Verbose "Updating Session Desktop application in $ApplicationGroupName"
        AuthenticationCheck
        $token = GetAuthToken -resource $Script:AzureApiUrl
        $apiVersion = "?api-version=2021-01-14-preview"
        switch ($PsCmdlet.ParameterSetName) {
            Name {
                $url = $Script:AzureApiUrl + "/subscriptions/" + $script:subscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.DesktopVirtualization/applicationGroups/" + $ApplicationGroupName + "/desktops/SessionDesktop/" + $apiVersion        
            }
            ResourceId {
                $url = $Script:AzureApiUrl + $ResourceId + "/desktops/SessionDesktop/" + $apiVersion        
            }
        }
        $parameters = @{
            uri     = $url
            Headers = $token
        }
        $body = @{
            properties = @{
            }
        }
        if ($friendlyName) { $body.properties.Add("friendlyName", $friendlyName) }
        if ($description) { $body.properties.Add("description", $description) }
    }
    Process {
        $jsonBody = $body | ConvertTo-Json
        $parameters = @{
            uri     = $url
            Method  = "PATCH"
            Headers = $token
            Body    = $jsonBody
        }
        $results = Invoke-RestMethod @parameters
        $results
    }
}