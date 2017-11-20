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

# Not changing our behavior based on build numbers right now, but the possibility exists
if ($BuildNumber) # -lt $Build1709
{
    $appXPackages = Get-AppxProvisionedPackage -Online
    $keepApps = @(
        '*Microsoft.MicrosoftStickyNotes*',
        '*Microsoft.WindowsAlarms*',
        '*Microsoft.WindowsCalculator*',
        '*Microsoft.WindowsCamera*',
        '*Microsoft.WindowsMaps*',
        '*Microsoft.WindowsSoundRecorder*',
        '*Microsoft.WindowsStore*'
    )

    foreach ($app in $appXPackages)
    {    
        $removeApp = $true

        foreach ($entry in $keepApps)
        {
            if ($($app.PackageName) -like $entry)
            {
                $removeApp = $false
            }
        }

        if ($removeApp -eq $true)
        {
            #$packageName = ($app -split ' : ')[1]
            Remove-AppxProvisionedPackage -Online -PackageName $($app.PackageName)
        }
    }
}