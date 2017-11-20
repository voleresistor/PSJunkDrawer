$WSUSServerName = ''
$WSUSUser = ''
$WSUSPass = ''
$LogPath = '\\dxpe.com\sccm\MDT\OS Deployment\Logs\Maintenance'

$WSUSPass = ConvertTo-SecureString $WSUSPass -AsPlainText -Force
$WSUSCred = New-Object System.Management.Automation.PSCredential ($WSUSUser,$WSUSPass)
$LogFile = "$LogPath\WSUS_Maint_Log-$(Get-Date -UFormat %d%m%y).log"

Add-Content -Value "==== Begin WSUS Maint - $(Get-Date) ====" -Path $LogFile

$MaintResult = (Invoke-Command -ComputerName $WSUSServerName -Credential $WSUSCred -ScriptBlock { Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name $args[0] -PortNumber 8530) -CleanupObsoleteComputers -CleanupObsoleteUpdates -CleanupUnneededContentFiles -DeclineExpiredUpdates -DeclineSupersededUpdates -CompressUpdates } -Args $WSUSServerName)

Add-Content -Value $MaintResult -Path $LogFile
Add-Content -Value "==== Finish WSUS Maint - $(Get-Date) ====`r`n" -Path $LogFile