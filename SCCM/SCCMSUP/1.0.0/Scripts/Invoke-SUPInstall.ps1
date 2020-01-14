function Invoke-SUPInstall
{
    <#
    .SYNOPSIS
      Invoke installation of available software updates on remote computers.

    .DESCRIPTION
     Function that will Invoke installation of available software updates on remote computers in Software Center that's available for the remote computer.

    .PARAMETER Computername
        Specify the remote computer you wan't to run the script against

    .PARAMETER SupName
        Specify the specific available software update you wan't to invoke an Installation of or all of them


    .EXAMPLE

        Invoke-SupInstall -Computername SD010 -SUPName KB3172605

        Invoke-SupInstall -Computername SD010 -SUPName All


    .NOTES
        FileName:           Invoke-SupInstall.ps1
        Original Author:    Timmy Andersson
        Original Contact:   @Timmyitdotcom
        Created:            2016-08-01
        Modified:           2020-13-01
        Modified By:        ogden.andrew@gmail.com

        Changelog:
            2020-13-01
                Replace use of WMI with CIM
                This required moving all activity into a scriptblock and running with Invoke-Command
    #>

    Param
    (
        [String][Parameter(Mandatory=$True, Position=1)]
        $Computername,

        [String][Parameter(Mandatory=$False, Position=2)]
        $ArticleID
    )

    Begin
    {
        <#
            Looking for SUps with these states
            Source:
            https://docs.microsoft.com/en-us/configmgr/develop/reference/core/clients/sdk/ccm_softwareupdate-client-wmi-class
        #>
        $AppEvalState0 = "0"
        $AppEvalState1 = "1"
    }

    Process
    {
        # If there was a specific article ID provided only attempt to install that one
        If ($ArticleID)
        {
            Foreach ($Computer in $Computername)
            {
                <#
                    For CIM usage we need to run the commands in a remote session or the static class method InstallUpdates won't accept our array of CCM_SoftwareUpdate
                    We also need to cast the array to [CimInstance[]] to convince the method to accept it, even though it's already an object directly created via
                        a cim instance request
                #>
                $ScriptBlock = {
                    $Application = (Get-CimInstance -Namespace "root\ccm\clientSDK" -ClassName CCM_SoftwareUpdate | Where-Object { ($_.EvaluationState -like "*$($Using:AppEvalState0)*" -or "*$($Using:AppEvalState1)*") -and $_.ArticleID -eq $Using:ArticleID })
                    Invoke-CimMethod -ClassName CCM_SoftwareUpdatesManager -Name InstallUpdates -Arguments @{ CCMUpdates = [CimInstance[]]$Application } -Namespace root\ccm\clientsdk
                }

                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
            }
        }
        # Install everything currently available
        Else
        {
            Foreach ($Computer in $Computername)
            {
                <#
                    For CIM usage we need to run the commands in a remote session or the static class method InstallUpdates won't accept our array of CCM_SoftwareUpdate
                    We also need to cast the array to [CimInstance[]] to convince the method to accept it, even though it's already an object directly created via
                        a cim instance request
                #>
                $ScriptBlock = {
                    $Application = (Get-CimInstance -Namespace "root\ccm\clientSDK" -ClassName CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($Using:AppEvalState0)*" -or "*$($Using:AppEvalState1)*"})
                    Invoke-CimMethod -ClassName CCM_SoftwareUpdatesManager -Name InstallUpdates -Arguments @{ CCMUpdates = [CimInstance[]]$Application } -Namespace root\ccm\clientsdk
                    #$Application | Foreach-Object { Invoke-CimMethod -ClassName CCM_SoftwareUpdatesManager -Name InstallUpdates -Arguments @{ CCMUpdates = [CimInstance[]]$_ } -Namespace root\ccm\clientsdk }
                }

                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
            }
        }
    }

    End {}
}