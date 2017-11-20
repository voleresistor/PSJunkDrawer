Add-Type -Path 'C:\Program Files\Update Services\API\Microsoft.UpdateServices.Administration.dll'
$UseSSL = $False
$PortNumber = 8530
$Server = $env:ComputerName
$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
$ReportLocation = "\\houmdt03.dxpe.com\WSUSMaintenance$\$Server\default.htm"
$SMTPServer = 'smtp.dxpe.com'
$SMTPPort = 25
$To = 'Andrew Ogden <andrew.ogden@dxpe.com>'
$From = "$Server <$Server@dxpe.com>"
$WSUSConnection = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer("$Server.$Domain",$UseSSL,$PortNumber)

#Clean Up Scope
$CleanupScopeObject = New-Object Microsoft.UpdateServices.Administration.CleanupScope
$CleanupScopeObject.CleanupObsoleteComputers = $True
$CleanupScopeObject.CleanupObsoleteUpdates = $True
$CleanupScopeObject.CleanupUnneededContentFiles = $True
$CleanupScopeObject.CompressUpdates = $True
$CleanupScopeObject.DeclineExpiredUpdates = $True
$CleanupScopeObject.DeclineSupersededUpdates = $True
$CleanupTASK = $WSUSConnection.GetCleanupManager()

$Results = $CleanupTASK.PerformCleanup($CleanupScopeObject)

$DObject = New-Object PSObject
$DObject | Add-Member -MemberType NoteProperty -Name "SupersededUpdatesDeclined" -Value $Results.SupersededUpdatesDeclined
$DObject | Add-Member -MemberType NoteProperty -Name "ExpiredUpdatesDeclined" -Value $Results.ExpiredUpdatesDeclined
$DObject | Add-Member -MemberType NoteProperty -Name "ObsoleteUpdatesDeleted" -Value $Results.ObsoleteUpdatesDeleted
$DObject | Add-Member -MemberType NoteProperty -Name "UpdatesCompressed" -Value $Results.UpdatesCompressed
$DObject | Add-Member -MemberType NoteProperty -Name "ObsoleteComputersDeleted" -Value $Results.ObsoleteComputersDeleted
$DObject | Add-Member -MemberType NoteProperty -Name "DiskSpaceFreed" -Value $Results.DiskSpaceFreed

#HTML style
$HeadStyle = "<style>"
$HeadStyle = $HeadStyle + "BODY{background-color:peachpuff;}"
$HeadStyle = $HeadStyle + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$HeadStyle = $HeadStyle + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$HeadStyle = $HeadStyle + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:palegoldenrod}"
$HeadStyle = $HeadStyle + "</style>"
$Date = Get-Date

$DObject | ConvertTo-Html -Head $HeadStyle -Body "<h2><p>DXPE Deployment WSUS Cleanup Results: $Server</h2></p><h3><p>$date</p></h3>" | Out-File $ReportLocation -Force

#Send-MailMessage -To $To -from $FROM -subject "WSUS Clean Up Report" -smtpServer $SMTPServer -Attachments $ReportLocation -Port $SMTPPort