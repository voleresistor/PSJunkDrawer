# Simple script for use with SCCM baselines to remediate the status of XBox services

$aSvcNames = @(
    'XblAuthManager',
    'XblGameSave',
    'XboxGipSvc',
    'XboxNetApiSvc'
)

$oSvcs = Get-Service | Where-Object { $aSvcNames -contains $_.Name }

foreach ($s in $oSvcs) {
    Set-Service -Name $($s.Name) -StartupType 'Disabled'
    Stop-Service -Name $($s.Name) -Force
}