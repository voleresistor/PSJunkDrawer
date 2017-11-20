# Disable Windows 10 Game Bar
$version = (Get-WmiObject Win32_OperatingSystem -Property Version).Version -replace ('\.',',')

$Guid = '{0cea1d83-4928-4a0a-bf8b-b11e167003bc}'
$StubVal = 'reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR /v AppCaptureEnabled /t REG_DWORD /d 0 /f'
if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid"))
{
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components' -Name $Guid -ItemType 'Directory' -Force | Out-Null

    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'StubPath' -PropertyType 'String' -Value $StubVal
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name '@' -PropertyType 'String' -Value 'Disable AppCapture'
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'IsInstalled' -PropertyType 'DWORD' -Value 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}
else
{
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}

$Guid = '{5613cae8-8289-4883-81ed-368745f21937}'
$StubVal = 'reg add HKCU\System\GameConfigStore /v GameDVR_Enabled /t REG_DWORD /d 0 /f'
if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid"))
{
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components' -Name $Guid -ItemType 'Directory' -Force | Out-Null

    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'StubPath' -PropertyType 'String' -Value $StubVal
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name '@' -PropertyType 'String' -Value 'Disable GameDVR'
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'IsInstalled' -PropertyType 'DWORD' -Value 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}
else
{
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}