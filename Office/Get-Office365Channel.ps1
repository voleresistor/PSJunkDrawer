function Get-Office365Channel
{
    param()

    $CTRConfigurationPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" 
    $UpdateChannels = @{
        'Semi-Annual' = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
        'Current' = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
        'Monthly' = 'http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6';
        'Preview' = 'http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6'
    }

    $CDNBaseUrl = (Get-ItemProperty -Path $CTRConfigurationPath -Name "CDNBaseUrl" -ErrorAction SilentlyContinue).CDNBaseUrl
    return(($UpdateChannels.GetEnumerator() | Where-Object {$_.Value -eq $CDNBaseUrl}).Name)
}