$regPath = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'
$keyName = "{" + (New-Guid).Guid + "}"
$firstRunName = 'StubPath'
$firstRunVal = 'REG.EXE ADD "HKCU\Software\Microsoft\Windows Defender" /v UIFirstRun /t REG_DWORD /d 0 /f'
$defaultName = '(Default)'
$defaultVal = 'Disable Windows Defender First Run'

if (!(Test-Path -Path "$regPath\$keyName" -ErrorAction SilentlyContinue))
{
    New-Item -Path $regPath -Name $keyName -ItemType Directory -Force | Out-Null
}

New-ItemProperty -Path "$regPath\$keyName" -Name $defaultName -Value $defaultVal | Out-Null
New-ItemProperty -Path "$regPath\$keyName" -Name $firstRunName -Value $firstRunVal | Out-Null