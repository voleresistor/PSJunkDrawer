# Creates AD group and user collection in SCCM
# CreateAppStore -CMAppName <AppName>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$CMAppName
)

$MWBaseName = "Nightly-"
Import-Module ActiveDirectory
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")

$CMAppName = "AppDeploy_" + $CMAppName
$SiteCode = Get-PSDrive -PSProvider CMSITE
$OUAppDeploy = “OU=AppDeployments-Computers,OU=Groups,DC=dxpe,DC=corp”
$Domain = "Dxpe"
CD "$($SiteCode):"

$Description = "Nightly Deployment -- " + $CMAppName + "  Application."
$Query = 'select *  from  SMS_R_System where SMS_R_System.SystemGroupName = "' + $Domain + '\\' + $CMAppName + '"'

New-ADGroup –GroupScope Global -Name $CMAppName –path $OUAppDeploy -Description "Nightly Deployment"

$schedule = New-CMSchedule -RecurInterval Minutes -RecurCount 15
New-CMDeviceCollection -Name $CMAppName -LimitingCollectionId "HOU000B3" -RefreshType Periodic -RefreshSchedule $schedule
Add-CMDeviceCollectionQueryMembershipRule -RuleName $CMAppName -Collectionname $CMAppName -QueryExpression $Query

$CMCollection = Get-CMDeviceCollection -Name $CMAppName
Move-CMObject -FolderPath "HOU:\DeviceCollection\Workstations\Deployments\NightlyDeployments" -InputObject $CMCollection

#Create MW
$MWStart = "22:00"
$MWEnd = "06:00"
    
$StartTime = [DateTime]::Parse($MWStart) 
$EndTime = [DateTime]::Parse($MWEnd) 
 
$MWName = $MWBaseName + (get-date -UFormat "%B %d")
Set-Location "$($SiteCode.Name):\"

#Create The ScheduleToken 
$Schedule = New-CMSchedule -RecurInterval Days -RecurCount 1 -Start $StartTime -End $EndTime
Write-Host "Setting MW: '$($MWName)' on $($CMCollection) &gt; $($MWStart) - $($MWEnd)"
 
New-CMMaintenanceWindow -CollectionID $CMCollection.CollectionID -Schedule $Schedule -Name $MWName | Out-Null