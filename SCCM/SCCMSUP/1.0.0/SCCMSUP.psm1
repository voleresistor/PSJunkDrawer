<#
    Custom functions for remotely managing SCCM software updates.
    
    Created 01/14/20
    
    Changelog:
        01/14/20 - v 1.0.0
            Initial build
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