Function Get-AvdNetworkInfo {
    <#
    .SYNOPSIS
    Gets the sessionhost network information 
    .DESCRIPTION
    The function will help you getting insights about the AVD network configuration. 
    .PARAMETER HostpoolName
    Enter the AVD Hostpool name
    .PARAMETER ResourceGroupName
    Enter the AVD Hostpool resourcegroup name
    .PARAMETER SessionHostName
    This parameter accepts a single sessionhost name
    .EXAMPLE
    Get-AvdNetworkInfo -HostpoolName <string> -ResourceGroupName <string>
    .EXAMPLE
    Get-AvdNetworkInfo -HostpoolName <string> -ResourceGroupName <string> -SessionHostName avd-0.domain.local
    #>
    [CmdletBinding(DefaultParameterSetName = 'Hostpool')]
    param (
        [parameter(Mandatory, ParameterSetName = 'Hostpool')]
        [parameter(Mandatory, ParameterSetName = 'Sessionhost')]
        [ValidateNotNullOrEmpty()]
        [string]$HostpoolName,

        [parameter(Mandatory, ParameterSetName = 'Hostpool')]
        [parameter(Mandatory, ParameterSetName = 'Sessionhost')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [parameter(ParameterSetName = 'Sessionhost')]
        [ValidateNotNullOrEmpty()]
        [string]$SessionHostName
    )
    Begin {
        Write-Verbose "Start searching for networkinfo."
        AuthenticationCheck
        $token = GetAuthToken -resource $script:AzureApiUrl
        $apiVersion = "?api-version=2021-03-01"
    }
    Process {
        switch ($PsCmdlet.ParameterSetName) {
            Sessionhost {
                $Parameters = @{
                    HostPoolName      = $HostpoolName
                    ResourceGroupName = $ResourceGroupName
                    SessionHostName   = $SessionHostName
                }
            }
            Default {
                $Parameters = @{
                    HostPoolName      = $HostpoolName
                    ResourceGroupName = $ResourceGroupName
                }
            }
        }
        try {
            $SessionHosts = Get-AvdSessionHostResources @Parameters
        }
        catch {
            Throw "No sessionhosts found, $_"
        }
        $SessionHosts | ForEach-Object {
            $nicParameters = @{
                uri = $script:AzureApiUrl + $_.networkprofile.networkinterfaces.id + $apiVersion
                Headers = $token    
                Method = "GET"
            }
            $nsgNicParameters = @{
                uri = $script:AzureApiUrl + $_.networkprofile.networkinterfaces.id + "/effectiveNetworkSecurityGroups" + $apiVersion
                Headers = $token    
                Method = "POST"
            }

            $requestNicInfo = Invoke-RestMethod @nicParameters
            try {
                $requestNicNsgInfo = (Invoke-RestMethod @nsgNicParameters).value
            }
            catch {
                $requestNicNsgInfo = $false
            }
            $networkInfo = $requestNicInfo.properties.ipConfigurations.properties
            $networkInfo | Add-Member -NotePropertyName nicId -NotePropertyValue $requestNicInfo.Id
            $networkInfo | Add-Member -NotePropertyName nicNsg -NotePropertyValue $requestNicNsgInfo

            $nsgSubnetParameters = @{
                uri = $Script:AzureApiUrl+ $networkInfo.subnet.id + $apiVersion
                Headers = $token    
                Method = "GET"
            }
            $nsgSubnetInfo = Invoke-RestMethod @nsgSubnetParameters
            $_ | Add-Member -NotePropertyName NetworkCardInfo -NotePropertyValue $networkInfo -Force
            $_ | Add-Member -NotePropertyName SubnetInfo -NotePropertyValue $nsgSubnetInfo.properties -Force
        }
    }
    End {
        $SessionHosts
    }
}