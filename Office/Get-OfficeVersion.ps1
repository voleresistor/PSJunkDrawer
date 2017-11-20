[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [string]$ImportPath = "$PSScriptRoot\..\Import"
)

foreach ($f in (Get-childItem -Path $ImportPath))
{
    . $($f.FullName)
}

# Create TS Environment object
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Collect office installs. We're searching for 2010, 2013, or 2016
$OfficeInstalls = Get-InstalledSoftware -ProductName "Microsoft Office" | Where-Object {$_.AppGUID -match "^(\{)[9A-C]{1}[0-1]{1}1[4-6]{1}0000\-001[1-4]{1}\-[0-9a-fA-F]{4}\-[0-1]{1}000\-0000000FF1CE(\}){0,1}$"}
$OfficeInstalls > C:\Officeps1.txt

# Create and populate TS Env variables
if ($OfficeInstalls)
{
    $tsenv.Value('OfficeInstalled') = 'true'
    $tsenv.Value('OfficeVersion') = $($($OfficeInstalls.AppVersion) -split ('\.'))[0]
    $tsenv.Value('OfficeArch') = $($OfficeInstalls.SoftwareArchitecture)
    $tsenv.Value('OfficeGuid') = $($OfficeInstalls.AppGUID)
}