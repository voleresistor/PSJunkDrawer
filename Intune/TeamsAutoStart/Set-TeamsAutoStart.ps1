param (
    [string]$SettingPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',

    [string]$SettingName = 'Teams',

    [bool]$RemoveValue = $true
)

if ($RemoveValue) {
    Remove-ItemProperty -Path $SettingPath -Name $SettingName -ErrorAction SilentlyContinue
}
