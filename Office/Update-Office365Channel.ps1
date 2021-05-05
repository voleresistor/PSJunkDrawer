function Update-Office365Channel
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Semi-Annual', 'Current', 'Monthly', 'Preview')]
        [string]$TargetChannel
    )

    $CTRConfigurationPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" 
    $UpdateChannels = @{
        'Semi-Annual' = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
        'Current' = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
        'Monthly' = 'http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6';
        'Preview' = 'http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6'
    }

    $CDNBaseUrl = (Get-ItemProperty -Path $CTRConfigurationPath -Name "CDNBaseUrl" -ErrorAction SilentlyContinue).CDNBaseUrl

    if ($CDNBaseUrl -eq $null) {
        Write-Warning "No CDNBaseURL in registry. Is Office 365 installed?"
        exit(1)
    }

    $UpdateChannel = $UpdateChannels[$TargetChannel]
    $CurrentChannel = ($UpdateChannels.GetEnumerator() | Where-Object {$_.Value -eq $CDNBaseUrl}).Name

    if ($CDNBaseUrl -notmatch $UpdateChannel) {
        Write-Host "Updating from $CurrentChannel to $TargetChannel channel."

        # Set new update channel 
        Set-ItemProperty -Path $CTRConfigurationPath -Name "CDNBaseUrl" -Value $UpdateChannel -Force

        # Trigger hardware inventory - Speed up SCCM reporting?
        #Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" -MethodName "TriggerSchedule" -Arguments @{ sScheduleID = '{00000000-0000-0000-0000-000000000001}' }
    }
    else
    {
        # No need to change update channel
        Write-Host "Update channel is already $TargetChannel."
    }
}