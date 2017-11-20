<#
Set-DFSBaseline.ps1

Set and maintain a limited set of configuration baselines for DFS servers. Limited mostly to
Configuring the installed state of key Windows Features such as DFSR and BranchCache.

Author: Andrew Ogden
    aogden@dxpe.com

Last edit: 05/18/2015 aogden

Changes:
    05/19 - Add switches for Add/Remove/All/SendEmail. I don't think I'll let computers remediate
            automatically, but these switches will make it easy for the admin to come in
            and clean up manually after reading the report.
#>

param(
    [string]$MailTarget,
    [string]$SmtpServer = "smtp.dxpe.com",
    [switch]$AddNeeded,
    [switch]$RemoveExtra,
    [switch]$RemediateAll,
    [switch]$SendEmail,
    [switch]$NotDfs
)

$dfsFeatureList = @("FileAndStorage-Services", "File-Services", "FS-FileServer", "FS-BranchCache", "FS-Data-Deduplication", "FS-DFS-Namespace", "FS-DFS-Replication", "FS-Resource-Manager", "Storage-Services", "NET-Framework-45-Features", "NET-Framework-45-Core", "NET-WCF-Services45", "NET-WCF-TCP-PortSharing45", "RDC", "RSAT", "RSAT-Role-Tools", "RSAT-File-Services", "RSAT-DFS-Mgmt-Con", "RSAT-FSRM-Mgmt", "FS-SMB1", "User-Interfaces-Infra", "Server-Gui-Mgmt-Infra", "Server-Gui-Shell", "PowerShellRoot", "PowerShell", "PowerShell-ISE", "WoW64-Support")
# TODO: Config script to verify firewall rules as well as features
$dfsFireWallList = @("DFS Management","File Server Remote Management","DFS Replication","Remote File Server Resource Manager Management")
$installedFeatures = (Get-WindowsFeature | Where-Object {$_.Installed -eq $True})

$allFireWallList = @("Windows Remote Management","Remote Volume Management","Remote Event Log Management")
$enabledFwGroups = (Get-NetFirewallRule | Select DisplayGroup | Where-Object {$_.Enabled -eq $True})
$removeFeature = @()

function SetRemoteManagement (){
    foreach ($group in $allFireWallList){
        Enable-NetFirewallRule -DisplayGroup $group -Enabled True
    }

    Set-Service -Name vds -StartupType Automatic
    Start-Service -Name vds
}

function SetDfsFireWall (){
    foreach ($group in $dfsFireWallList){
        Enable-NetFireWallRule -DisplayGroup $group -Enabled True
    }
}

function SetDfsFeatures (){
    foreach ($feature in $installedFeatures){
        if ($dfsFeatureList | Where-Object {$_ -eq $feature.Name}){
            $dfsFeatureList = $dfsFeatureList -ne $feature.Name
        } else {
            $removeFeature = $removeFeature += $feature.Name
        }
    }
    
    Write-Host "Features to be installed:"
    $dfsFeatureList
    Write-Host "`r`nFeatures to be removed:"
    $removeFeature
    
    if ($AddNeeded -or $RemediateAll){
        Add-WindowsFeature -Name $dfsFeatureList
    }
    
    if ($RemoveExtra -or $RemediateAll){
        Remove-WindowsFeature -Name $removeFeature
    }
    
    if ($SendEmail){
        if (($dfsFeatureList -ne $false) -or ($removeFeature -ne $false)){
            foreach ($a in $removeFeature){
                $removeFeature = $removeFeature -ne $a
                $removeFeature = $removeFeature += "$a<br>"
            }
        
            foreach ($b in $dfsFeatureList){
                $dfsFeatureList = $dfsFeatureList -ne $b
                $dfsFeatureList = $dfsFeatureList += "$b<br>"
            }
        
            $mailMessage = "The following necessary changes were detected on <b>$env:ComputerName -</b><br><br><i>Features to be installed:</i><br>$dfsFeatureList<br><br><i>Features to be removed:</i><br>$removeFeature"
            Send-MailMessage -From $env:COMPUTERNAME@dxpe.com -To $MailTarget -Subject "Detected WindowsFeature chaanges needed" -Body $mailMessage -SmtpServer $SmtpServer -Priority Normal -BodyAsHtml
        }
    }
}

function SetForDfs (){
    SetDfsFeatures
    SetDfsFireWall
}

function main (){
    SetRemoteManagement

    if (!$NotDfs){
        SetForDfs
    }
}

main