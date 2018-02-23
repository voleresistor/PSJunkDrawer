# Windows baseline remediation script
$MmsString = 'AutoUpdateDisable=1`r`nSilentAutoUpdateEnable=0'
$x86Path = "$env:windir\System32\Macromed\Flash"
$x64Path = "$env:windir\SysWOW64\Macromed\Flash"

if (Test-Path -Path $x86Path)
{
    Set-Content -Value $MmsString -Path "$x86File\mms.cfg" -Force
}

if (($(Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture -eq '64-bit') -and (Test-Path -Path $x64Path))
{
    Set-Content -Value $MmsString -Path "$x64File\mms.cfg" -Force
}

# Windows baseline detection script
$x86Path = "$env:windir\System32\Macromed\Flash"
$x64Path = "$env:windir\SysWOW64\Macromed\Flash"
$flashPresent = $true;

if ((Test-Path -Path $x86Path) -and !(Test-Path -Path "$x86Path\mms.cfg"))
{ $flashPresent = $false }

if ((Test-Path -Path $x64Path) -and ($(Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture -eq '64-bit') -and !(Test-Path -Path "$x64Path\mms.cfg"))
{ $flashPresent = $false }

return $flashPresent