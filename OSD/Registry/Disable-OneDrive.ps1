$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'
$keyName = 'OneDrive'
$valName = 'DisableFileSyncNGSC'
$linkPath = 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
$value = 1

if (!(Test-Path -Path "$regPath\$keyName" -ErrorAction SilentlyContinue))
{
    New-Item -Path $regPath -Name $keyName -ItemType Directory -Force | Out-Null
}

New-ItemProperty -Path "$regPath\$keyName" -Name $valName -Value $value -PropertyType DWORD | Out-Null

foreach ($UserProfile in (Get-ChildItem -Path 'C:\Users' -ErrorAction SilentlyContinue))
{
    if (Test-Path -Path "$($UserProfile.FullName)\$linkPath" -ErrorAction SilentlyContinue)
    {
        Remove-Item -Path "$($UserProfile.FullName)\$linkPath" -ErrorAction SilentlyContinue -Force | Out-Null
    }
}

$version = (Get-WmiObject Win32_OperatingSystem -Property Version).Version -replace ('\.',',')

$Guid = '{397ec3f0-96c3-4e83-bf7c-6421472645e2}'
$StubVal = 'cmd /C del /F "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"'
if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid"))
{
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components' -Name $Guid -ItemType 'Directory' -Force | Out-Null

    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'StubPath' -PropertyType 'String' -Value $StubVal
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name '@' -PropertyType 'String' -Value 'Remove OneDrive Link'
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'IsInstalled' -PropertyType 'DWORD' -Value 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}
else
{
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$Guid" -Name 'Version' -PropertyType 'String' -Value $version
}
