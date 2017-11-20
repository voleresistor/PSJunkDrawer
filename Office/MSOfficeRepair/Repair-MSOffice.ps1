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
$OfficeConfig = "config$OfficeArch-$OfficeVer.xml"
$SetupExePath = "C:\MSOCache\All Users\$OfficeGuid-C\Setup.exe"
$SetupArgs = "/repair `"ProPlus`" /Config `"$PSScriptRoot\$OfficeConfig`""

# Perform the repair
Start-Process -FilePath $SetupExePath -ArgumentList $SetupArgs -Wait