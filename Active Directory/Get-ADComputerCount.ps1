param
(
    $Domains = @('dxpe.corp', 'dxpe.com'),
    $SiteName = 'HOU'
)

Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

$days14 = 0
$days30 = 0
$days60 = 0
$days90 = 0
$total = 0
$managed = 0
$unmanaged = 0
$toBeInstalled = 0
$unknown = 0
$failed = 0
$computersUnder14 = @()

foreach ($domain in $Domains)
{
    $activeComputers = Get-ADComputer -Filter { Enabled -eq 'True' } -Server $domain -Properties LastLogonDate
    $total += $activeComputers.Count
    
    foreach ($computer in $activeComputers)
    {
        [datetime]$lastLogonDate = $computer.LastLogonDate
        if ($lastLogonDate -gt $((Get-Date).AddDays(-14)))
        {
            $days14++
            $computersUnder14 += $computer.Name
        }
        
        if($lastLogonDate -gt $((Get-Date).AddDays(-30)))
        {
            $days30++
        }
        
        if($lastLogonDate -gt $((Get-Date).AddDays(-60)))
        {
            $days60++
        }
        
        if($lastLogonDate -gt $((Get-Date).AddDays(-90)))
        {
            $days90++
        }
    }
    
    Clear-Variable -Name activeComputers
}

Set-Location -Path "$SiteName`:\"
foreach ($device in $computersUnder14)
{
    $state = (Get-CMDevice -Name $device).EPDeploymentState
    switch($state)
    {
        1 {$unmanaged++}
        2 {$toBeInstalled++}
        3 {$managed++}
        4 {$failed++}
        default {$unknown++}
    }
    
    
}

Write-Host "Total - $total"
Write-Host "14 days - $days14"
Write-Host "30 days - $days30"
Write-Host "60 days - $days60"
Write-Host "90 days - $days90"
Write-Host "`r`nStatus of computers under 14 days:"
Write-Host "`tUnManaged - $unmanaged"
Write-Host "`tTo be installed - $toBeInstalled"
Write-Host "`tManaged - $managed"
Write-Host "`tFailed - $failed"
Write-Host "`tUnknown - $unknown"