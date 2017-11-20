param
(
    [string]$CollectionName,
    [string]$ModulePath = 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
)

begin
{
    # Import ConfigManager module
    try
    {
        Import-Module $ModulePath

        $OldLocation = Get-Location
        Set-Location -Path 'HOU:\'
    }
    catch
    {
        Write-Host "Can't import CM module!"
        Exit 1
    }

    #Class to organize data
    class ClientResults
    {
        [string]
        $ClientName

        [string]
        $IsClient

        [string]
        $ClientVersion

        [string]
        $HasInstaller
    }

    # Array for collected data
    $ClientDeviceResults = @()
}
process
{
    # Get all devices in specified collection
    $DeviceList = Get-CMCollectionMember -CollectionName $CollectionName

    foreach ($Device in $DeviceList)
    {
        # Create a new instance of custom class and add client name
        $ClientData = [ClientResults]::new()
        $ClientData.ClientName = $Device.Name

        # Get client version from WMI
        $ClientVer = Get-WmiObject -Namespace 'root\ccm' -Class 'SMS_Client' -ComputerName $($Device.Name) -ErrorAction SilentlyContinue
        $ClientData.ClientVersion = $ClientVer.ClientVersion
        if ($ClientVer)
        {
            $ClientData.IsClient = 'True'
        }
        else
        {
            $ClientData.IsClient = 'False'
        }

        # Check for presence of client installer
        if (Test-Path -Path "\\$($Device.Name)\admin$\ccmsetup\ccmsetup.exe")
        {
            $ClientData.HasInstaller = 'True'
        }
        else
        {
            $ClientData.HasInstaller = 'False'
        }

        $ClientDeviceResults += $ClientData
        Clear-Variable ClientData,ClientVer
    }
}
end
{
    Set-Location -Path $($OldLocation.Path)
    Remove-Module -Name 'ConfigurationManager' -ErrorAction SilentlyContinue
    return $ClientDeviceResults
}