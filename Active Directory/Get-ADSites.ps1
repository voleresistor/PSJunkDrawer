function Get-AdSites
{
    <#
    .SYNOPSIS
    Return information about AD sites in the specified forest.
    
    .DESCRIPTION
    Use .NET to gather detailed AD site information in the specified forest. This function also relies on Get-AdForestObject.
    
    .PARAMETER DomainName
    Name of the forest domain to gather data from. If not specified, the current forest is used.

    .PARAMETER Credential
    A PSCredential object containing to be used to logon to the remote server or domain.
    
    .EXAMPLE
    Get-AdSites -DomainName example.com

    Get detailed site information from the example.com forest.

    .EXAMPLE
    Get-AdSites

    Get detailed site information from the current forest.
    
    .NOTES
    Main process borrowed from another website. I didn't make a note of the source at the time.
    #>
    [cmdletbinding()]            
    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string]$DomainName,

        [Parameter(Mandatory=$false, Position=2)]
        [System.Management.Automation.PsCredential]$Credential
    )

    # A script dependency
    . Get-AdForestObject.ps1

    if ($DomainName -and $Credential)
    {
        $Sites = (Get-ADForestObject -ForestName $DomainName -Credential $Credential).Sites
    }
    else
    {
        $Sites = (Get-ADForestObject $DomainName).Sites
    }
               
    $obj = @() 
    foreach ($Site in $Sites)
    {            
        $obj += New-Object -Type PSObject -Property(            
            @{            
                "SiteName"  = $site.Name;            
                "SubNets" = $site.Subnets;            
                "Servers" = $Site.Servers;
                "SiteLinks" = $site.SiteLinks.Name          
            }            
        )            
    }
    return $obj
}