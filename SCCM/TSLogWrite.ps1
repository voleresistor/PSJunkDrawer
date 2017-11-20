<#
    Solution: OSD
    Purpose: Facilitate logging to BDD.log from within PowerShell scripts in TS environment
    Version: 1.0 - Feb 03, 2017

    Author: Andrew Ogden
        Email: andrew.ogden@dxpe.com
#>

function TSLogWrite
{
    param
    (
        [string]$Value,
        [string]$Component,
        [string]$Context,
        [string]$Type,
        [string]$Thread,
        [string]$File,
        [string]$Log
    )

    $LogDate = Get-Date
    $FormattedDate = "$("{0:00}" -f ($LogDate.Month))-$("{0:00}" -f ($LogDate.Day))-$($LogDate.Year)"
    $FormattedTime = $LogDate.TimeOfDay -match ("\d{2}:\d{2}:\d{2}.\d{3}")
    $FormattedTime = $Matches[0]
    $FormattedTime = $FormattedTime + "+000"

    Add-Content -Path $Log -Value "<![LOG[$Value]LOG]!><time=`"$FormattedTime`" date=`"$FormattedDate`" component=`"$Component`" context=`"$Context`" type=`"$Type`" thread=`"$Thread`" file=`"$File`">"
}