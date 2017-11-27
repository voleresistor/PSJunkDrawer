<#
    Repair-MSOffice

    Uses OSD task sequence variables set by Get-OfficeVersion to build an execute an Office repair command.
    This is necessary to repair some damage done to Office installs during Windows 10 OS upgrades. This script
    relies on the presence of the config.xml files.

    Last Edited: 11/27/2017

    Author: Andrew Ogden
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [string]$ConfigRoot = "$PSScriptRoot" #Defaults to same directory as script
)

$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$OfficeGuid = $tsenv.Value('OfficeGuid')
$OfficeArch = $tsenv.Value('OfficeArch')
switch ($tsenv.Value('OfficeVersion'))
{
    14 { $OfficeVer = '2010' }
    15 { $OfficeVer = '2013' }
    16 { $OfficeVer = '2016' }
}

# Build the config file name
$OfficeConfig = "$ConfigRoot\config$OfficeArch-$OfficeVer.xml"
$SetupExePath = "C:\MSOCache\All Users\$OfficeGuid-C\Setup.exe"
$SetupArgs = "/repair `"ProPlus`" /Config `"$OfficeConfig`""

# Perform the repair
Start-Process -FilePath $SetupExePath -ArgumentList $SetupArgs -Wait