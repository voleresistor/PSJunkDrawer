
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE
CD "$($SiteCode):"

$UName = "All Security and Critical -- May"
$DName = "All Security and Critical - May - Pre-Deployment Server Updates"
$CName = "Pre-Deployment - Server Updates"

$ADay = "2015/5/13"
$ATime = "13:00"

$EDay = "2015/5/14"
$ETime = "00:50"

Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $UName -CollectionName $CName -DeploymentName $DName -DeploymentAvailableDay $ADay -DeploymentAvailableTime $ATime -EnforcementDeadline $ETime -EnforcementDeadlineDay $EDay -DeploymentType Required -SendWakeUpPacket $False -VerbosityLevel AllMessages -TimeBasedOn Local -UserNotification DisplayAll -SoftwareInstallation $False -AllowRestart $False -RestartServer $False -RestartWorkstation $False -PersistOnWriteFilterDevice $False -DisableOperationsManagerAlert $True -GenerateOperationsManagerAlert $False -ProtectedType RemoteDistributionPoint -UseBranchCache $True -DownloadFromMicrosoftUpdate $False -AllowUseMeteredNetwork $False

