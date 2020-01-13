<#    
.SYNOPSIS    
  Invoke installation of available software updates on remote computers     
     
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
 
function Invoke-SupInstall 
{ 
    Param 
    ( 
        [String][Parameter(Mandatory=$True, Position=1)]
        $Computername, 

        [String][Parameter(Mandatory=$True, Position=2)]
        $ArticleID 
    )

    Begin 
    { 
        $AppEvalState0 = "0" 
        $AppEvalState1 = "1" 
        #$ApplicationClass = [cimclass]"root\ccm\clientSDK:CCM_SoftwareUpdatesManager" 
    } 
    
    Process 
    { 
        If ($ArticleID -Like "All" -or $ArticleID -like "all") 
        { 
            Foreach ($Computer in $Computername) 
            {
                $ScriptBlock = {
                    $Application = (Get-CimInstance -Namespace "root\ccm\clientSDK" -ClassName CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($Using:AppEvalState0)*" -or $_.EvaluationState -like "*$($Using:AppEvalState1)*"}) 
                    Write-Host $Application.Count
                    $Application | Foreach-Object { Invoke-CimMethod -ClassName CCM_SoftwareUpdatesManager -Name InstallUpdates -Arguments @{ CCMUpdates = [CimInstance[]]$_ } -Namespace root\ccm\clientsdk }
                }
                
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
            }
        } 
        Else 
        {
            Foreach ($Computer in $Computername) 
            {
                $ScriptBlock = {
                    $Application = (Get-CimInstance -Namespace "root\ccm\clientSDK" -ClassName CCM_SoftwareUpdate | Where-Object { ($_.EvaluationState -like "*$($Using:AppEvalState0)*" -or $_.EvaluationState -like "*$($Using:AppEvalState1)*") -and $_.ArticleID -eq $Using:ArticleID }) 
                    Invoke-CimMethod -ClassName CCM_SoftwareUpdatesManager -Name InstallUpdates -Arguments @{ CCMUpdates = [CimInstance[]]$Application } -Namespace root\ccm\clientsdk
                }
                
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
            }
        } 
    } 

    End {} 
}