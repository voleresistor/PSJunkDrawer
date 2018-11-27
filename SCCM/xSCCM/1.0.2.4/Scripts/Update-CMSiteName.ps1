#region Update-CMSiteName
function Update-CMSiteName
{
    <# 
        .SYNOPSIS 
            Update CM site description.
        .DESCRIPTION
            Microsoft doesn't provide a simple method to change a site name from within the CM console. This function uses WMI calls to edit the site description.
        .PARAMETER  SiteName 
            Three letter site code.
        .PARAMETER  Siteserver 
            FQDN of a site server for the site you wish to change.
        .PARAMETER NewSiteDesc
            New description to apply to the site.
        .EXAMPLE 
            Update-CMSiteName -SiteName TST -SiteServer cm01.test.com -NewSiteDesc "Test.com SCCM Site - TST - v1606"
            Update the site description of site named TST on server cm01.test.com.
        .Notes 
            Author : Andrew Ogden
            Email  : andrew.ogden@dxpe.com
            Date   : 
    #>
    param
    (
        [string]$SiteName = 'HOU',
        [string]$SiteServer = 'housccm03.dxpe.com',
        [string]$NewSiteDesc
    )
    
    $FullSite = Get-WmiObject -Class 'SMS_SCI_SiteDefinition' -Namespace "root/SMS/site_$SiteName" -ComputerName $SiteServer
    
    if (!($NewSiteDesc))
    {
        Write-Host "Current site description is - $($FullSite.SiteName)"
        $NewSiteDesc = Read-Host -Prompt "Enter new description: "   
    }
    
    $OldSiteDesc = $FullSite.SiteName
    $FullSite.SiteName = $NewSiteDesc
    $FullSite.Put()
    
    $CurrentSiteDesc = (Get-WmiObject -Class 'SMS_SCI_SiteDefinition' -Namespace "root/SMS/site_$SiteName" -ComputerName $SiteServer).SiteName
    if ($CurrentSiteDesc -ne $NewSiteDesc)
    {
        Write-Host 'There was an error updating the site description.' -ForegroundColor Red
    }
    else
    {
        Write-Host "Site description successfully updated.`r`nOld: $OldSiteDesc`r`nNew: $NewSiteDesc"
    }
}
#endregion