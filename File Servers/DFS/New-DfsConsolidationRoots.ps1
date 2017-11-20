param(
    [string]$RootList,
    [string]$ShareList,
    [switch]$DoNetworkStuff,
    [string]$DnsDomainName = 'dxpe.com'
)

$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

<# Add the DFS Namespace feature and management console #>
Write-Host 'Checking for and installing DFS Namespace role...' -NoNewline
if ((Get-WindowsFeature -Name 'FS-DFS-Namespace' -ErrorAction 'SilentlyContinue').InstallState -eq 'Available'){
    Add-WindowsFeature -Name 'FS-DFS-Namespace' -IncludeManagementTools
}
Write-Host ' Done'

<# Add the key to enable Consolidation Readirection to the registry #>
Write-Host 'Checking for and installing reg key to support Consolidation Mode... ' -NoNewline
if (!(new-item -Type 'Registry' -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated' -ErrorAction 'SilentlyContinue')){
    Write-Host "`r`nERROR: Failed to create reg key HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated!" -ForegroundColor 'Red'
    exit 1
}

if (!(new-itemproperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated' -Name 'ServerConsolidationRetry' -Value 1 -ErrorAction 'SilentlyContinue')){
    Write-Host "`r`nERROR: Failed to set reg value HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated\ServerConsolidationRetry = 1" -ForegroundColor 'Red'
    exit 1
}

if (!(new-itemproperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated' -Name 'LogServerConsolidation' -Value 1 -ErrorAction 'SilentlyContinue')){
    Write-Host "`r`nERROR: Failed to set reg value HKLM:\SYSTEM\CurrentControlSet\Services\Dfs\Parameters\Replicated\LogServerConsolidation = 1" -ForegroundColor 'Red'
    exit 1
}
Write-Host ' Done'

if ($RootList){
    Write-Host "Creating roots from $RootList... " -NoNewline

    foreach ($root in Get-Content -Path $RootList){
        <# Create a directory and share for the namespace #>
        if (!(New-Item -Type 'Directory' -Path "C:\DFSRoots\#$root" -ErrorAction 'SilentlyContinue')){
            Write-Host "ERROR: Failed to create folder for root #$root!" -ForegroundColor 'Red'
            continue
        }
        if (!(New-SmbShare -Name "#$root" -Path "C:\DFSRoots\#$root" -ErrorAction 'SilentlyContinue')){
            Write-Host "ERROR: Failed to create SMB share for #$root!" -ForegroundColor 'Red'
            continue
        }
        <# Create the DFS namespace #>
        if (!(New-DfsnRoot -Type 'Standalone' -TargetPath "\\$myFQDN\#$root" -Path "\\$myFQDN\#$root" -ErrorAction 'SilentlyContinue')){
            Write-Host "ERROR: Failed to create DFS root for #$root!" -ForegroundColor 'Red'
            continue
        }
        <# Add an alternative computername #>
        #if ($DoNetworkStuff){
        #    netdom computername localhost /add "$root.$DnsDomainName"
        #}
    }
    <# Update DNS #>
    #if ($DoNetworkStuff){
    #    ipconfig /registerdns
    #}
    Write-Host ' Done'
}

if ($ShareList){
    Write-Host "Creating shares from $ShareList..." -NoNewline
    <# Add shares to the new roots #>
    $NewShares = Import-Csv -Path $ShareList -Delimiter ','

    foreach ($share in $NewShares){
        Write-Host "\\$myFQDN\#$($share.Root)\$($share.Share)"
        if (!(New-DfsnFolder -Path "\\$myFQDN\#$($share.Root)\$($share.Share)" -TargetPath "$($share.TargetPath)" -ErrorAction 'SilentlyContinue')){
            Write-Host "ERROR: Failed to create DFS folder \\$myFQDN\#$($share.Root)\$($share.Share)" -ForegroundColor 'Red'
            continue
        }
    }
    Write-Host ' Done'
}

#if ($DoNetworkStuff){
#    Restart-Computer
#}