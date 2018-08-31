function Update-SiteName
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
    
    .PARAMETER NewName
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
        [string]$SiteServer,

        [Parameter(Mandatory=$true)]
        [string]$NewName
    )
    $site = Get-WmiObject -Class SMS_SCI_SiteDefinition -Namespace root/Sms/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.SiteCode -eq $SiteCode}
    $oldName = $site.SiteName

    $Site.SiteName = $NewName
    $Site.Put()

    if ($oldName -eq $($site.SiteName))
    {
        return "Site name failed to update."
    }
    else
    {
        return "Site name successfully updated."
    }
}