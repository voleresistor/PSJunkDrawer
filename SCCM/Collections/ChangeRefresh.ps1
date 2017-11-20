Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE
$SiteFileLoc = "D:\Work\Locations.csv"

$cvsfile = Import-Csv -path $SiteFileLoc

ForEach ( $line in $cvsfile ) {
 write-host $line.Name
 CD "$($SiteCode):"
 $Schedule = New-CMSchedule –RecurInterval Days –RecurCount 1  
 Set-CMDeviceCollection –Name $line.Name –RefreshSchedule $Schedule -RefreshType "periodic"  
  }  