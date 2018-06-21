param
(
    [Switch]$SendMessage = $False,
    [string]$searchBase = "dc=dxpe,dc=corp",
    [string]$Server = "dxpe.corp",
    [string]$fileshare = "c:\temp",
    [int]$maxAgeDays = 30
)
    
    <#
    
    .DISCLAIMER
    
    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
    
    #>
    
    <#Make sure you have installed the S.DS.P module from https://gallery.technet.microsoft.com/scriptcenter/Using-SystemDirectoryServic-0adf7ef5 on the server where you will be running the script.
    
    Thanks to Jiri Formacek for creating the foundation of the script. I just put the cherry on top!
    
    Optimizations tweaked by Sean Kearney, Platforms PFE and 'Scripting Guy'
    
    #>
    
    #Import the S.DS.P PowerShell module 
    
    Import-Module S.DS.P

    $ts=[DateTime]::Now.AddDays(0-$maxAgeDays).ToFileTimeUtc().ToString() 
    
    #LDAP queries for LAPS statistics 
    $enrolledComputers=@(Find-LdapObject -LdapConnection $Server -searchFilter "(&(objectClass=computer)(ms-MCS-AdmPwdExpirationTime=*))" -searchBase $searchBase -PropertiesToLoad @('canonicalname','lastlogontimestamp')) 
    $nonEnrolledComputers=@(Find-LdapObject -LdapConnection $Server -searchFilter "(&(objectClass=computer)(!(ms-MCS-AdmPwdExpirationTime=*)))" -searchBase $searchBase -PropertiesToLoad @('canonicalname','lastlogontimestamp')) 
    $expiredNotRefreshed=@(Find-LdapObject -LdapConnection $Server -searchFilter "(&(objectClass=computer)(ms-MCS-AdmPwdExpirationTime<=$ts))" -searchBase $searchBase -PropertiesToLoad @('canonicalname','lastlogontimestamp')) 
    
    #Write the LAPS information (summary and detail) to a temporary file in the previously specified share 
    
    $Content=@"
    COUNTS
    ——
    Enrolled: $($enrolledComputers.Count)
    Not enrolled: $($nonEnrolledComputers.Count)
    Expired: $($expiredNotRefreshed.Count)
    DETAILS
    ——-
    Enrolled
    ——-
    $($enrolledComputers | Select-Object 'canonicalname',@{l='lastlogon'; e={[datetime]::FromFileTime($_.lastlogontimestamp).ToString("MM-dd-yy")}} | Out-String)
    
    Not enrolled
    ————
    $($nonEnrolledComputers | Select-Object 'canonicalname',@{l='lastlogon'; e={[datetime]::FromFileTime($_.lastlogontimestamp).ToString("MM-dd-yy")}} | Out-String)
    
    Expired
    ——-
    $($expiredNotRefreshed | Select-Object 'canonicalname',@{l='lastlogon'; e={[datetime]::FromFileTime($_.lastlogontimestamp).ToString("MM-dd-yy")}} | Out-String)
"@

$FileDate = (Get-Date).tostring("MM-dd-yyyy-hh-mm-ss")
$Filename=$Fileshare+'\'+$Filedate+'LAPSReport.txt'
Add-Content -Value $Content -Path $Filename

If ($SendMessage)
{
    #Edit the variables below to specify the email addresses and SMTP server to use
    $EmailFrom = 'lapshealth@tailspintoys.com'
    $EmailTo='emailaddress@tailspintoys.com'
    $today = Get-Date
    $EmailSubject = 'LAPS Health Report for ' + $today.ToShortDateString() 
    $EmailBody=$Content
    $smtpserver = "smtp.tailspintoys.com"
    
    Send-MailMessage -Body $EmailBody -From $EmailFrom -To $EmailTo -Subject $EmailSubject -SmtpServer $smtpserver
}