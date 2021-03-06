$regPath = 'HKLM:\SYSTEM\CurrentControlSet\services\LanmanWorkstation'
$keyName = 'Parameters'
$valName = 'EnableSecuritySignature'
$value = 0

if (!(Test-Path -Path "$regPath\$keyName" -ErrorAction SilentlyContinue))
{
    New-Item -Path $regPath -Name $keyName -ItemType Directory -Force | Out-Null
}

New-ItemProperty -Path "$regPath\$keyName" -Name $valName -Value $value -PropertyType DWORD | Out-Null