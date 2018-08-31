function Get-SiteName
{
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER SiteCode
    Parameter description
    
    .PARAMETER SiteServer
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    #>

    param (
        [CmdletBinding()]
        [Parameter(Mandatory=$true)]
        [string]$SiteCode,

        [Parameter(Mandatory=$true)]
        [string]$SiteServer
    )

    # Get current site name
    $site = Get-WmiObject -Class SMS_SCI_SiteDefinition -Namespace root/Sms/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.SiteCode -eq $SiteCode}
    return $site.SiteName
}