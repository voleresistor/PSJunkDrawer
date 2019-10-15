# Get scriptdir
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

# Sideloading key vars
$KeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$KeyName = 'AllowAllTrustedApps'
$KeyValue = 1

# Attempt to enable AppX sideloading
try
{
    Set-ItemProperty -Path $KeyPath -Name $KeyName -Value $KeyValue
}
catch
{
    Write-Error "Failed to allow sideloading: $($_.Exception.Message)"
    return 101
}

# Wait 15 seconds for sideload keys
#Start-Sleep -Seconds 15

# Set WalkMe cookie
$env:Cookie_URL = "https://account.walkme.com/ExtensionDownload/downloadPage.html?guid=b5ce23e6f78740b6ab7fab859e184748&customer=dxp&profile=default&massConfig=1"

# Check for presence of WalkMe profile data
if (Test-Path -Path "$env:UserProfile\AppData\Local\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\Extensions\*WalkMe*")
{
    Write-Host "WalkMe is already installed"
    return 0
}
else
{
    try
    {
        Add-AppxPackage "\\houdfs03.dxpe.com\IT\Public\Installers\WalkMe\Edge\Walkme_Extension.appx"
        Start-Sleep -Seconds 5
    }
    catch
    {
        Write-Error "Failed to install the AppX package: $($_.Exception.Message)"
        return 102
    }
}

Write-Host "Installation complete!"