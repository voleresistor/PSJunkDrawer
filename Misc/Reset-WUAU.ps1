Stop-Service -Name wuauserv,cryptsvc,bits,msiserver

Remove-Item -Path 'C:\Windows\SoftwareDistribution' -Recurse -Force
Remove-Item -Path 'C:\Windows\System32\catroot2' -Recurse -Force

Start-Service -Name wuauserv,cryptsvc,bits,msiserver