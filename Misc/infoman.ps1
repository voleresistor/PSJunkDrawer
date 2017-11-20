# ==================================================
# infoman.ps1
# Andrew Ogden
# 06-23-2014
# ==================================================
#
# Schedule periodic uptime notifications to server as reminders of server uptimes
# or notify when a server starts up in case of crash or reboot.
#

param (
    [switch]$rebootEmail,
    [switch]$uptimeEmail,
    [string]$mailTo = 'aogden@dxpe.com'
)

# ==================================================
# Functions
# ==================================================

Function Mailer {
    param (
         [string]$emailTo,
         [string]$emailFrom,
         [string]$message,
         [string]$subject
    )
    
    $smtpserver="smtp.dxpe.com"     
    $smtp=new-object Net.Mail.SmtpClient($smtpServer) 
    $smtp.Send($emailFrom, $emailTo, $subject, $message) 
}

# ==================================================
# Execute Script
# ==================================================

# Determine information about last reboot
$lastReboot = (Get-WmiObject win32_ntlogevent -filter "LogFile='System' and EventCode='1074' and Message like '%restart%'" | Select-Object User,@{n="Time";e={$_.ConvertToDateTime($_.TimeGenerated)}} -First 1)

# Send reboot notification
if ($rebootEmail) {
    # Get date and time zone
    $date = (Get-Date)
    $timeZone = ([System.TimeZone]::CurrentTimeZone).StandardName

    # Send message
    $mailMessage = "$env:COMPUTERNAME was rebooted on $($lastReboot.Time) $timeZone by $($lastReboot.User)"
    $mailFrom = "$env:COMPUTERNAME@dxpe.com" 
    $mailSubject="$env:COMPUTERNAME Reboot" 

    Mailer -emailTo $mailTo -emailFrom $mailFrom -subject $mailSubject -message $mailMessage
}

# Calculate server uptime and send notice
if ($uptimeEmail) {
    # WMI dates are handled as strings so we have to use .ConvertToDate() to make them malleable
    $wmi = Get-WmiObject -Class win32_OperatingSystem
    $uptime = $wmi.ConvertToDateTime($wmi.LocalDateTime) - $wmi.ConvertToDateTime($wmi.LastBootupTime)

    $mailMessage = "$env:COMPUTERNAME has been up for: $($uptime.Days) days $($uptime.Hours) hours $($uptime.Minutes) minutes $($uptime.Seconds) seconds`r`nLast reboot was on $($lastReboot.Time) by $($lastReboot.User)"
    $mailFrom = "$env:COMPUTERNAME@dxpe.com"
    $mailSubject = "$env:COMPUTERNAME Uptime"

    Mailer -emailTo $mailTo -emailFrom $mailFrom -subject $mailSubject -message $mailMessage
}