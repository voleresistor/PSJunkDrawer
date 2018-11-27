<#
    Custom functions for common operations in SCCM and MDT.
    
    Created 06/20/16
    
    Changelog:
        06/20/16 - v 1.0.0
            Initial build
            Added Split-DriverSource
        03/16/17 - v 1.0.1
            Added Get-CMCollectionMembership
        06/27/17 - v 1.0.2.2
            Added Clear-CMCache
            Added Get-UpgradeReadiness
            Added Get-UpgradeHistory
            Update module manifest to require PS5 for use of Class in new functions
        06/29/17 - v1.0.2.3
            Add help comments boilerplate
            Add help comments to Split-DriverSource and Update-CMSiteName
#>

<#
    Help comments boilerplate

    <# 
        .SYNOPSIS 
            Short description.
        .DESCRIPTION
            Long description.
        .PARAMETER  Param1 
            Description of Param1.
        .PARAMETER  Param2 
            Description of Param2.
        .EXAMPLE 
            Get-Example -Param1
            Example 1
        .EXAMPLE
            Get-Example -Param2
            Example 2
        .Notes 
            Author : 
            Email  : 
            Date   : 
            WebSite: 
    #> 
#>

foreach ($Script in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1)
{
    . $Script.FullName
}