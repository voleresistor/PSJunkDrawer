# Simple script for use with SCCM baselines to check the status of XBox services

$aSvcNames = @(
    'XblAuthManager',
    'XblGameSave',
    'XboxGipSvc',
    'XboxNetApiSvc'
)

$oSvcs = Get-Service | Where-Object { $aSvcNames -contains $_.Name }

$boolRemediate = $false
foreach ($s in $oSvcs) {
    if (-not(($s.StartType -eq 'Disabled') -and ($s.Status -eq 'Stopped'))) {
        $boolRemediate = $true
        break
    }
}

return $boolRemediate