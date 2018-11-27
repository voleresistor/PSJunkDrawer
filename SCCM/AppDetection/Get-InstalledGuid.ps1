function Get-InstalledGuid
{
    param
    (
        [parameter(Mandatory=$true, Position=1)]
        [string]$ProductGUID,

        [Parameter(Mandatory=$false)]
        [switch]$IsUninstalled # Use to detect lack of presence (For standalone uninstall applications)
    )

    $UninstallRegKeys=
    @(
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
        "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    )

    #Gather data based on each reg key
    foreach($UninstallRegKey in $UninstallRegKeys)
    {
        try
        {
            $HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)
            $UninstallRef = $HKLM.OpenSubKey($UninstallRegKey)
            $Applications = $UninstallRef.GetSubKeyNames()
        }
        catch
        {
            Continue
        }
        
        #Populate app data
        foreach ($App in $Applications)
        {
            $AppRegistryKey = $UninstallRegKey + "\\" + $App
            $AppDetails = $HKLM.OpenSubKey($AppRegistryKey)

            #Extract the GUID from the MSI uninstall key
            if ($($AppDetails.GetValue("UninstallString")) -match "msiexec(.exe){0,1} \/[XIxi]{1}\{.*")
            {
                $matchGuid = $($($AppDetails.GetValue("UninstallString")) -replace "msiexec(.exe){0,1} \/[XIxi]{1}\{","{")
            }

            if ($matchGuid -match $ProductGUID)
            {
                if ($IsUninstalled)
                {
                    return $null
                }
                return $true
            }
        }   
    }
}

# Guid match string
# Office 2010: "^(\{)[9A-C]{1}[0-1]{1}140000\-001[1-4]{1}\-[0-9a-fA-F]{4}\-[0-1]{1}000\-0000000FF1CE(\}){0,1}$"
# Office 2013: "^(\{)[9A-C]{1}[0-1]{1}150000\-001[1-4]{1}\-[0-9a-fA-F]{4}\-[0-1]{1}000\-0000000FF1CE(\}){0,1}$"
# Office 2016: "^(\{)[9A-C]{1}[0-1]{1}160000\-001[1-4]{1}\-[0-9a-fA-F]{4}\-[0-1]{1}000\-0000000FF1CE(\}){0,1}$"
$GuidMatch = "^(\{)[9A-C]{1}[0-1]{1}140000\-001[1-4]{1}\-[0-9a-fA-F]{4}\-[0-1]{1}000\-0000000FF1CE(\}){0,1}$"

# Application is installed
#Get-InstalledGuid -ProductGuid $GuidMatch

# Application is not installed
Get-InstalledGuid -ProductGuid $GuidMatch -IsUninstalled