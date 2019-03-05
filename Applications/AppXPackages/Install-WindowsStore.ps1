function Install-WindowsStore
{
    param
    (
        [string]$ComputerName,
        [string]$InstallPath = 'C:\Program Files\WindowsApps'
    )

    # Gather some data
    $arch = (Get-WmiObject -Class win32_OperatingSystem -Properties 'OSArchitecture').OSArchitecture

    # Define package pre-requisites
    $x86PreRequisites = @(
        'Microsoft.NET.Native.Framework.1.7_1.7.25531.0_x64__8wekyb3d8bbwe',
        'Microsoft.NET.Native.Runtime.1.7_1.7.25531.0_x64__8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.26706.0_x64__8wekyb3d8bbwe'
    )

    $x64PreRequisites = @(
        'Microsoft.NET.Native.Framework.1.7_1.7.25531.0_x86__8wekyb3d8bbwe',
        'Microsoft.NET.Native.Runtime.1.7_1.7.25531.0_x86__8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.26706.0_x86__8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11811.1001.18.0_neutral_split.scale-100_8wekyb3d8bbwe'
    )

    # Verify package pre-requisites
    foreach ($p in $x86PreRequisites)
    {
        if (!(Get-AppPackage -AllUsers $p))
        {
            Write-Error -Exception 'Prerequisite not found' -Message "Please verify that $p is installed correctly prior to installing this package."
            #Copy-Item -Path "$p" -Destination $InstallPath -Recurse -Force
            #Add-AppxPackage -DisableDevelopmentMode -Register "$InstallPath\$p\AppxManifest.xml"
        }
    }

    if ($arch -eq '64-bit')
    {
        foreach ($p in $x64PreRequisites)
        {
            if (!(Get-AppPackage -AllUsers $p))
            {
                Write-Error -Exception 'Prerequisite not found' -Message "Please verify that $p is installed correctly prior to installing this package."
                #Copy-Item -Path "$p" -Destination $InstallPath -Recurse -Force
                #Add-AppxPackage -DisableDevelopmentMode -Register "$InstallPath\$p\AppxManifest.xml"
            }
        }
    }

    # Install Microsoft Store
    Copy-Item -Path "Microsoft.WindowsStore_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe" -Destination $InstallPath -Recurse -Force
    Copy-Item -Path "Microsoft.WindowsStore_11811.1001.18.0_x64__8wekyb3d8bbwe" -Destination $InstallPath -Recurse -Force

    Add-AppxPackage -DisableDevelopmentMode -Register "$InstallPath\Microsoft.WindowsStore_11811.1001.18.0_x64__8wekyb3d8bbwe\AppxManifest.xml"
    Add-AppxPackage -DisableDevelopmentMode -Register "$InstallPath\Microsoft.WindowsStore_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe\AppxMetaData\AppxBundleManifest.cml"
}