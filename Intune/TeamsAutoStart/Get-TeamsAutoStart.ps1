param (
    [string]$SettingPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',

    [string]$SettingName = 'Teams',

    [bool]$IntuneCheck = $true
)

$myState = Get-ItemProperty -Path $SettingPath -Name $SettingName -ErrorAction SilentlyContinue

if ($myState) {
    Write-Host "Value is present."
    exit 1
}
else {
    Write-Host "Value is not present."
    exit 0
}