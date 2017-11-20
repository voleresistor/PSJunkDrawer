param(
    [ValidateSet('DiskSpace','Replication','AddPrinter','DeletePrinter','ChangePrinter')]
    [string]$Action,

    [ValidateSet('High','Normal','Low')]
    [string]$Priority = "High",

    [array]$MailTo = @('andrew.ogden@dxpe.com'),

    [string]$MailFrom = "$env:COMPUTERNAME@dxpe.com",

    [string]$SmtpServer = "smtp.dxpe.com"
)
#===============================================
# These functions are deprecated
#===============================================
#if ($DiskSpace){
#    $body = "A disk on $env:COMPUTERNAME has fallen below the minimum free space threshold."
#    $subject = "Low Disk Space"
#}
#
#if ($Replication){
#    $body = "A failure has occurred that resulted in a full halt in replication with a partner of #$env:COMPUTERNAME."
#    $subject = "Replication Failure"
#}

# Collect message data and edit email subject and body based on alert subject
switch ($Action){
    "DiskSpace" {
        $message = (Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Diagnosis-PLA/Operational"; ID=2031} | Select-Object -First 1)
        $body = "A disk on $env:COMPUTERNAME has fallen below the minimum free space threshold. The message was:<br><br><i>$($message.Message)</i>"
        $subject = "Low Disk Space"
    }
    "Replication" {
        $message = (Get-WinEvent -FilterHashtable @{LogName="DFS Replication"; ID=5008} | Select-Object -First 1)
        $body = "A failure has occurred that resulted in a full halt in replication with a partner of $env:COMPUTERNAME. The message was:<br><br><i>$($message.Message)</i>"
        $subject = "Replication Failure"
    }
    "AddPrinter" {
        $MailTo += 'vu.le@dxpe.com'
        Import-Module ActiveDirectory

        $message = (Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-PrintService/Operational"; ID=300} | Select-Object -First 1)
        $sid = $message.UserId.Value
        $corpAcct = Get-ADUser -Server dxpe.corp -Filter { Sid -eq $sid }
        $comAcct = Get-ADUser -Server dxpe.com -Filter { Sid -eq $sid }

        $body = "A new printer has been added to $env:COMPUTERNAME. The message was:<br><br><i>$($message.Message)</i><br><br>The user is <b>$($corpAcct.UserPrincipalName)$($comAcct.UserPrincipleName)</b>"
        $subject = "New Printer"

        Remove-Module ActiveDirectory
    }
    "DeletePrinter" {
        $MailTo += 'vu.le@dxpe.com'
        Import-Module ActiveDirectory

        $message = (Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-PrintService/Operational"; ID=301} | Select-Object -First 1)
        $sid = $message.UserId.Value
        $corpAcct = Get-ADUser -Server dxpe.corp -Filter { Sid -eq $sid }
        $comAcct = Get-ADUser -Server dxpe.com -Filter { Sid -eq $sid }

        $body = "A printer has been deleted from $env:COMPUTERNAME. The message was:<br><br><i>$($message.Message)</i><br><br>The user is <b>$($corpAcct.UserPrincipalName)$($comAcct.UserPrincipleName)</b>"
        $subject = "Printer Deleted"

        Remove-Module ActiveDirectory
    }
    "ChangePrinter" {
        $MailTo += 'vu.le@dxpe.com'
        Import-Module ActiveDirectory

        $message = (Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-PrintService/Operational"; ID=306} | Select-Object -First 1)
        $sid = $message.UserId.Value
        $corpAcct = Get-ADUser -Server dxpe.corp -Filter { Sid -eq $sid }
        $comAcct = Get-ADUser -Server dxpe.com -Filter { Sid -eq $sid }

        $body = "A printer has been changed on $env:COMPUTERNAME. The message was:<br><br><i>$($message.Message)</i><br><br>The user is <b>$($corpAcct.UserPrincipalName)$($comAcct.UserPrincipleName)</b>"
        $subject = "Printer Changed"

        Remove-Module ActiveDirectory
    }
    default {
        $body = "An event that matches a configured alert on $env:COMPUTERNAME has ocurred, but due to a misconfiguration in the alert, the event could not be determined."
        $subject = "Unknown Event"
    }
}

# Configure anonymous credential
$anonUsername = 'anonymous'
$anonPassword = ConvertTo-SecureString -String 'anonymous' -AsPlainText -Force
$anonCredential = New-Object System.Management.Automation.PSCredential($anonUsername,$anonPassword)

# Send message using anonymous credentials
foreach ($address in $MailTo){
    Send-MailMessage -To $address -From $MailFrom -Subject $subject -Body $body -SmtpServer $SmtpServer -Priority $Priority -BodyAsHtml -Credential $anonCredential
}