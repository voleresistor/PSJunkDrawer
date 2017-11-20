Set-Service -Name BITS -StartupType Disabled
Stop-Service -Name BITS -Force

Remove-Item -Path "$env:AllUsersProfile\Application Data\Microsoft\Network\Downloader" -Recurse -Force

Set-Service -Name BITS -StartupType Automatic
Start-Service -Name BITS