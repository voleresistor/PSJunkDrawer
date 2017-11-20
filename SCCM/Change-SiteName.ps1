[CmdletBinding()]

param (
    [string]$SiteCode,
    [string]$SiteServer,
    [string]$SiteName
)

function Change-SiteName {
    $site = Get-WmiObject -Class SMS_SCI_SiteDefinition -Namespace root/Sms/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.SiteCode -eq $SiteCode}
    $Site.SiteName = $SiteName
    $Site.Put()
}

Change-SiteName