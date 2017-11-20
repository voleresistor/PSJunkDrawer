[CmdletBinding()]
param
(
)

# Store build numbers as variables
[int]$Build1607 = 10586
[int]$Build1703 = 14393
[int]$Build1709 = 16299

# Get this number as an int for easy comparison with above build variables
[int]$BuildNumber = (Get-WmiObject -Class Win32_Operatingsystem).BuildNumber

# Changing our behavior based on build numbers
if ($BuildNumber -lt $Build1709)
{
    $appXPackages = dism.exe /Online /Get-ProvisionedAppXPackages | Select-String PackageName
    #$keepApps = @('Microsoft.MicrosoftStickyNotes','Microsoft.Office.OneNote','Microsoft.WindowsFeedbackHub','Microsoft.WindowsSoundRecorder')

    Clear-Host
    Write-Host '***************************************************'
    Write-Host 'Begin removing extraneous AppX packages...'

    foreach ($app in $appXPackages)
    {
        #$skipPackage = 0
        #
        $packageName = ($app -split ' : ')[1]
        #foreach ($kApp in $keepApps)
        #{
        #    if ($packageName -like "$kApp*")
        #    {
        #        Write-Host "Skipping package $packageName"
        #        $skipPackage = 1
        #    }
        #}
        #
        #if ($skipPackage -eq 1)
        #{
        #    continue
        #}

        Write-Host "Remove $packageName... " -NoNewline   
        dism.exe /Online /Remove-ProvisionedAppXPackage /PackageName:$packageName
        if (!(dism.exe /online /Get-ProvisionedAppXPackages | Select-String $packageName))
        {
            Write-Host 'Done'
        }
        else
        {
            Write-Host 'Failed'
        }
    }

    Write-Host 'Done removing extraneous AppX packages!'
}
else
{
    # Remove provisioned packages
    Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -AllUsers
    
    # Remove non-provisioned packages that we don't want
    $PackageNameList = @('Microsoft.Advertising.Xaml',
    'Microsoft.BingFinance',
    'Microsoft.BingNews',
    'Microsoft.BingSports',
    'Microsoft.BingWeather',
    'Microsoft.CommsPhone',
    'Microsoft.ConnectivityStore',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.Office.OneNote',
    'Microsoft.Office.Sway',
    'Microsoft.OneConnect',
    'Microsoft.SkypeApp',
    'Microsoft.SkypeApp',
    'Microsoft.StorePurchaseApp',
    'microsoft.windowscommunicationsapps',
    'Microsoft.WindowsEmulatorbyMicrosoft',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsPhone',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameCallableUI',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo')
    
    foreach ($AppXPackage in $PackageNameList)
    {
        $i = 0
        while ($i -lt 5)
        {
            Write-Host "Removing $AppxPackage attempt $($i + 1)"
            Get-AppxPackage -Name $AppxPackage -AllUsers | Remove-AppxPackage -AllUsers
            if (!(Get-AppxPackage -Name $AppxPackage -AllUsers))
            {
                $i = 5
            }
            else
            {
                $i++
            }
        }
    }
    
}
