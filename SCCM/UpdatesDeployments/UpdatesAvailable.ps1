
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE
CD "$($SiteCode):"

$UName = "All Security and Critical -- March"
$DName = "All Security and Critical - March - Tier 3 Servers - Available"
$CName = "Tier 3"

$ADay = "2015/3/13"
$ATime = "10:00"

Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $UName -CollectionName $CName -DeploymentName $DName -DeploymentAvailableDay $ADay -DeploymentAvailableTime $ATime -DeploymentType Available -SendWakeUpPacket $False -VerbosityLevel AllMessages -TimeBasedOn Local -UserNotification DisplayAll -SoftwareInstallation $False -AllowRestart $False -RestartServer $True -RestartWorkstation $True -PersistOnWriteFilterDevice $False -DisableOperationsManagerAlert $True -GenerateOperationsManagerAlert $False -ProtectedType RemoteDistributionPoint -UseBranchCache $True -DownloadFromMicrosoftUpdate $False -AllowUseMeteredNetwork $False

