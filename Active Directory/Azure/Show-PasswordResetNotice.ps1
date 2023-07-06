# Change as suited for your environment
$PasswordAge = (Get-ItemProperty -Path 'HKCU:\Software\Puffer\ApplicationInstallation\PasswordReset' -Name 'DaysUntilExpiration').DaysUntilExpiration
#$TitleText = "Password Expiring"
$TitleText = "Your password is expiring"
$BodyText2 = "If you do not reset your password within $PasswordAge days your account will be locked. If you are unable to change your password or your password has already been changed, please contact tech support."
$HeaderText = "Puffer-Sweiven"

#Remove this if you want to use an URL and your own image instead
$HeroImagePath = "C:\Windows\Web\Wallpaper\Theme1\img1.jpg"

#If you want to you use your own URL use theese variables instead, also uncomment line 100 & 101
#$HeroImageFile = "Paste URL here if you want to download your own image from e.g an Azure Storage Account"
#$HeroImageName = "img1.jpg"

$Action = "https://account.activedirectory.windowsazure.com/ChangePassword.aspx"

$WindirTemp = Join-Path $Env:Windir -Childpath "Temp"
$UserTemp = $Env:Temp
$UserContext = [Security.Principal.WindowsIdentity]::GetCurrent()

Switch ($UserContext) {
    { $PSItem.Name -Match       "System"    } { Write-Output "Running as System"  ; $Temp =  $UserTemp   }
    { $PSItem.Name -NotMatch    "System"    } { Write-Output "Not running System" ; $Temp =  $WindirTemp }
    Default { Write-Output "Could not translate Usercontext" }
}

$logfilename = "PasswordNotificationRE"
$logfile = Join-Path $Temp -Childpath "$logfilename.log"

$LogfileSizeMax = 100

##############################
## Functions
##############################

function Test-WindowsPushNotificationsEnabled() {
	$ToastEnabledKey = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name ToastEnabled -ErrorAction Ignore).ToastEnabled
	if ($ToastEnabledKey -eq "1") {
		Write-Output "Toast notifications are enabled in Windows"
		return $true
	}
	elseif ($ToastEnabledKey -eq "0") {
		Write-Output "Toast notifications are not enabled in Windows. The script will run, but toasts might not be displayed"
		return $false
	}
	else {
		Write-Output "The registry key for determining if toast notifications are enabled does not exist. The script will run, but toasts might not be displayed"
		return $false
	}
}

function Display-ToastNotification() {

	$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
	$Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

	# Load the notification into the required format
	$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
	$ToastXml.LoadXml($Toast.OuterXml)
		
	# Display the toast notification
	try {
		Write-Output "All good. Displaying the toast notification"
		[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
	}
	catch { 
		Write-Output "Something went wrong when displaying the toast notification"
		Write-Output "Make sure the script is running as the logged on user"    
	}
	if ($CustomAudio -eq "True") {
		Invoke-Command -ScriptBlock {
			Add-Type -AssemblyName System.Speech
			$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
			$speak.Speak($CustomAudioTextToSpeech)
			$speak.Dispose()
		}    
	}
}

function Test-NTSystem() {  
	$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
	if ($currentUser.IsSystem -eq $true) {
		$true  
	}
	elseif ($currentUser.IsSystem -eq $false) {
		$false
	}
}

##############################s
## Scriptstart
##############################

If ($logfilename) {
    If (((Get-Item -ErrorAction SilentlyContinue $logfile).length / 1MB) -gt $LogfileSizeMax) { Remove-Item $logfile -Force }
    Start-Transcript $logfile -Append | Out-Null
    Get-Date
}

	#$HeroImagePath = Join-Path -Path $Env:Temp -ChildPath $HeroImageName
	#If (!(Test-Path $HeroImagePath)) { Start-BitsTransfer -Source $HeroImageFile -Destination $HeroImagePath }	

	##Setting image variables
	$LogoImage = ""
	$HeroImage = $HeroImagePath
	$RunningOS = Get-CimInstance -Class Win32_OperatingSystem | Select-Object BuildNumber

	$isSystem = Test-NTSystem
	if ($isSystem -eq $True) {
		Write-Output "Aborting script"
		Exit 1
	}

	$WindowsPushNotificationsEnabled = Test-WindowsPushNotificationsEnabled

	$PSAppStatus = "True"

	if ($PSAppStatus -eq "True") {
		$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
		$App = "Microsoft.CompanyPortal_8wekyb3d8bbwe!App"
		
		if (-NOT(Test-Path -Path "$RegPath\$App")) {
			New-Item -Path "$RegPath\$App" -Force
			New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD"
		}
		
		if ((Get-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -ErrorAction SilentlyContinue).ShowInActionCenter -ne "1") {
			New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD" -Force
		}
	}

	$AttributionText = "Information"

	$ActionButtonContent = "Change Password"
	$DismissButtonContent = "Remind me later"

	$CustomAudio = "False"
	$CustomAudioTextToSpeech = $Xml.Configuration.Option | Where-Object {$_.Name -like 'CustomAudio'} | Select-Object -ExpandProperty 'TextToSpeech'

	
	$Scenario = "Reminder"
		
	# Formatting the toast notification XML
	# Create the default toast notification XML with action button and dismiss button
	[xml]$Toast = @"
	<toast scenario="$Scenario">
	<visual>
	<binding template="ToastGeneric">
		<image placement="hero" src="$HeroImage"/>
		<image id="1" placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>
		<text placement="attribution">$AttributionText</text>
		<text>$HeaderText</text>
		<group>
			<subgroup>
				<text hint-style="title" hint-wrap="true" >$TitleText</text>
			</subgroup>
		</group>
		<group>
			<subgroup>     
				<text hint-style="body" hint-wrap="true" >$BodyText2</text>
			</subgroup>
		</group>
	</binding>
	</visual>
	<actions>
		<action activationType="protocol" arguments="$Action" content="$ActionButtonContent" />
		<action activationType="system" arguments="dismiss" content="$DismissButtonContent"/>
	</actions>
	</toast>
"@
	
	Display-ToastNotification

If ($logfilename) {
    Stop-Transcript | Out-Null
}

Exit 0