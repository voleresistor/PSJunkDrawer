function Convert-ContentIdToName
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ContentId,

        [Parameter(Mandatory=$true)]
        [string]$SiteCode,

        [Parameter(Mandatory=$true)]
        [string]$SiteServer
    )

    if ($ContentId -match ".\..")
    {
        $CID = ($ContentId -split ("\."))[0]
    }
    else
    {
        $CID = $ContentId
    }

    return (Get-WmiObject -Namespace "root\sms\site_$SiteCode" -ComputerName $SiteServer -Class SMS_Deploymenttype -Filter "ContentID = '$CID' and PriorityInLatestApp = '1'").AppModelName
}