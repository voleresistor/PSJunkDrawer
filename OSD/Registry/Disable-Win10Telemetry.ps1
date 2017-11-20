param()

$keyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'
$keyName = 'DataCollection'
$keyProp = 'AllowTelemetry'
<#
The following value can be one of 0-3
0 - Enterprise SKU only. Disable telemetry for enterprise devices
1 - Basic
2 - Enhanced
3 - Full
#>
$propVal = 0

if (!(Test-Path -Path "$keyRoot\$keyName"))
{
    New-Item -Path $keyRoot -Name $keyName | Out-Null
    New-ItemProperty -Path "$keyRoot\$keyName" -Name $keyProp -Value $propVal | Out-Null
}
else
{
    New-ItemProperty -Path "$keyRoot\$keyName" -Name $keyProp -Value $propVal | Out-Null
}