<#Disable WSUServer value to 1Run Windows Capability to directly download the components from internetEnable WSUServer value to 0#>
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
Restart-Service "Windows Update" -ErrorAction SilentlyContinue
Write-Host "Adding Components…" -ForegroundColor Green
Get-WindowsCapability -Name "RSAT*" -Online | Select-Object name | ForEach-Object {
    Add-WindowsCapability -Name $_.Name -Online
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 1
Restart-Service "Windows Update" -ErrorAction SilentlyContinue