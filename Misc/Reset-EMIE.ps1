<# Force Refresh IE Enterprise Mode #>

<# Clear IE Cache for User #>
RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8

<# Remove Version Registry Key #>
Remove-ItemProperty -Path 'hkcu:\Software\Microsoft\Internet Explorer\Main\EnterpriseMode' -Name CurrentVersion -ErrorAction SilentlyContinue

<# Send Instructions #>
Write-Host "Close and restart Internet Explorer to refresh the Enterise Mode site list."