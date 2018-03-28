function New-DateDiff
{
    param
    (
        [Parameter(Mandatory=$false)]
        $Password,

        [Parameter(Mandatory=$false)]
        $UserName,

        [Parameter(Mandatory=$true)]
        $SiteServer,
    
        [Parameter(Mandatory=$true)]
        $RequestGuid,

        $execFrequency = 5,
        $secondEmail = 2880, # 2 days
        $deny = 7200 # 5 days
    )

    if (!$Password -and !$UserName)
    {
        $SiteCode = (Get-WmiObject -ComputerName $SiteServer -Namespace root\SMS -Class "SMS_ProviderLocation").SiteCode
        $results = Get-WmiObject -Class 'SMS_UserApplicationRequest' -Namespace "root\sms\site_$SiteCode" -ComputerName $SiteServer
    }
    else
    {
        $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
        $SiteCode = (Get-WmiObject -ComputerName $SiteServer -Namespace root\SMS -Class "SMS_ProviderLocation" -Credential $mycreds).SiteCode
        $results = Get-WmiObject -Class 'SMS_UserApplicationRequest' -Namespace "root\sms\site_$SiteCode" -ComputerName $SiteServer -Credential $mycreds
    }

    <#$results = Invoke-Command -ComputerName $SiteServer -Credential $mycreds -ScriptBlock {
        Get-WmiObject -Class 'SMS_UserApplicationRequest' -Namespace "root\sms\site_$($args[0])" -ComputerName $($args[1])
    } -ArgumentList $SiteCode,$siteServer#>

    $APPAPR = foreach ($e in $results)
    {
        if ($e.RequestGuid -eq $RequestGuid)
        {
            $e
        }
    }
    $appName = $APPAPR.Application

    # Apparently, I'm not using this block
    #$history = $APPAPR.RequestHistory | Select-Object -First 1
    $currentComment = $APPAPR.Comments
    $currentAdmin = $APPAPR.LastModifiedBy
    $requestUser = $APPAPR.User
    $userSam = ($requestUser -split '\\')[1]

    $currentTime,$null = $APPAPR.LastModifiedDate -split ('\.')
    $currentTime = ([datetime]::ParseExact($currentTime, 'yyyyMMddHHmmss', $null))
    $currentState = $APPAPR.CurrentState

    #$date = $APPAPR.LastModifiedDate
    $today = [datetime]::UtcNow
    $action = "NotDoingShit"

    if ($currentState -eq 1)
    {
        if (($currentTime -lt $today) -and ($currentTime -gt $today.AddMinutes(-$execFrequency)))
        {
            $action = "FirstEmail"
        }

        if (($currentTime -lt $today.AddMinutes(-$secondEmail)) -and ($currentTime -gt $today.AddMinutes(-($secondEmail + $execFrequency))))
        {
            $action = "SecondEmail"
        }

        if (($currentTime -lt $today.AddMinutes(-$deny)))
        {
        $action = "AutoDeny"
        }
    }
    elseif ($currentState -eq 2)
    {
        if (($currentTime -lt $today) -and ($currentTime -gt $today.AddMinutes(-$execFrequency)))
        {
            $action = "CancelEmail"
        }
    }
    elseif ($currentState -eq 3)
    {
        if (($currentTime -gt $today.AddMinutes(-$execFrequency)) -and ($currentTime -lt $today))
        {
            $action = "DenialEmail"
        }
    }
    elseif ($currentState -eq 4)
    {
        if (($currentTime -gt $today.AddMinutes(-$execFrequency)) -and ($currentTime -lt $today))
        {
            $action = "ApprovalEmail"
        }
    }

    if ($action -ne "NotDoingShit")
    {
        Add-Content -Value "$(Get-Date) - $appName - $currentTime - $action" -Path C:\Temp\actions.log
    }
}