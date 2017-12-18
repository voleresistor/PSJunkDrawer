Add-Type -Path 'C:\Program Files\Update Services\API\Microsoft.UpdateServices.Administration.dll'
$UseSSL = $False
$PortNumber = 8530
$Server = $env:ComputerName
$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
$ReportLocation = "\\houmdt03.dxpe.com\WSUSMaintenance$\$Server\default.htm"
$DetailLocation = "\\houmdt03.dxpe.com\WSUSMaintenance$\$Server\detail.htm"
$SMTPServer = 'smtp.dxpe.com'
$SMTPPort = 25
$To = 'Andrew Ogden <andrew.ogden@dxpe.com>'
$From = "$Server <$Server@dxpe.com>"
$WSUSConnection = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer("$Server.$Domain",$UseSSL,$PortNumber)

#HTML style
$HeadStyle = "<style>"
$HeadStyle = $HeadStyle + "BODY{background-color:peachpuff;}"
$HeadStyle = $HeadStyle + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$HeadStyle = $HeadStyle + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$HeadStyle = $HeadStyle + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:palegoldenrod}"
$HeadStyle = $HeadStyle + "</style>"
$ReportDate = Get-Date

#Update details
$Source = $WSUSConnection.getupdates() | Where-Object {($_.IsDeclined -eq 'True') -or ($_.IsSuperseded -eq 'True') -or ($_.PublicationState -eq 'Expired')}
$ObsoleteUpdate = @()
foreach ($upd in $Source)
{
	[datetime]$date = $upd.CreationDate
    [string]$date = Get-Date -Date $date -Format MM/dd/yyyy
    if ($upd.IsDeclined -eq 'True')
    {
        $updState = 'Declined'
    }
    elseif ($upd.IsSuperseded -eq 'True')
    {
        $updState = 'Superseded'
    }
    elseif ($upd.PublicationState -eq 'Expired')
    {
        $updState = 'Expired'
    }
    else
    {
        $updState = 'Unknown'
    }
	$entry = new-object -TypeName psobject
	$entry | Add-Member -MemberType NoteProperty -Name Title -Value $upd.Title
	$entry | Add-Member -MemberType NoteProperty -Name Severity -Value $upd.MsrcSeverity
	$entry | Add-Member -MemberType NoteProperty -Name KBNum -Value $($upd.KnowledgebaseArticles -replace ('[{|}]',''))
	$entry | Add-Member -MemberType NoteProperty -Name Product -Value $($upd.ProductTitles -replace ('[{|}]',''))
	$entry | Add-Member -MemberType NoteProperty -Name PublishedDate -Value $date
	$entry | Add-Member -MemberType NoteProperty -Name State -Value $updState
	$ObsoleteUpdate += $entry
}
$ObsoleteUpdate = $ObsoleteUpdate | Sort-Object -Property KBNum
$ObsoleteUpdate | ConvertTo-Html -Head $HeadStyle -Body "<h2><p>Obsolete Updates:$($Source.Count)</p></h2><h3><p>$ReportDate</p></h3><p><a href=`"$ReportLocation`">Back to summary</a></p>" | Out-File -FilePath $DetailLocation

#Clean Up Scope
$CleanupScopeObject = New-Object Microsoft.UpdateServices.Administration.CleanupScope
$CleanupScopeObject.CleanupObsoleteComputers = $True
$CleanupScopeObject.DeclineExpiredUpdates = $True
$CleanupScopeObject.DeclineSupersededUpdates = $True
$CleanupScopeObject.CleanupObsoleteUpdates = $True
$CleanupScopeObject.CleanupUnneededContentFiles = $True
$CleanupScopeObject.CompressUpdates = $True
$CleanupTASK = $WSUSConnection.GetCleanupManager()

$Results = $CleanupTASK.PerformCleanup($CleanupScopeObject)

$DObject = New-Object PSObject
$DObject | Add-Member -MemberType NoteProperty -Name "SupersededUpdatesDeclined" -Value $Results.SupersededUpdatesDeclined
$DObject | Add-Member -MemberType NoteProperty -Name "ExpiredUpdatesDeclined" -Value $Results.ExpiredUpdatesDeclined
$DObject | Add-Member -MemberType NoteProperty -Name "ObsoleteUpdatesDeleted" -Value $Results.ObsoleteUpdatesDeleted
$DObject | Add-Member -MemberType NoteProperty -Name "UpdatesCompressed" -Value $Results.UpdatesCompressed
$DObject | Add-Member -MemberType NoteProperty -Name "ObsoleteComputersDeleted" -Value $Results.ObsoleteComputersDeleted
$DObject | Add-Member -MemberType NoteProperty -Name "DiskSpaceFreed" -Value $Results.DiskSpaceFreed

$DObject | ConvertTo-Html -Head $HeadStyle -Body "<h2><p>DXPE Deployment WSUS Cleanup Results: $Server</h2></p><h3><p>$ReportDate</p></h3><p><a href=`"$DetailLocation`">Update details</a></p>" | Out-File $ReportLocation -Force

#Send-MailMessage -To $To -from $FROM -subject "WSUS Clean Up Report" -smtpServer $SMTPServer -Attachments $ReportLocation -Port $SMTPPort