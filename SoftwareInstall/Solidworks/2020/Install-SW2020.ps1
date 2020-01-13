function Install-SW2020
{
    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateSet('A','B','C','D','E')]
        [string]$InstallType
    )
    
    # Log install start
    Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Begin Solidworks 2020 install"
    
    # Hash table of location subnets and local servers
    $locationTable = @{
        '10.103.64' = 'tyldfs01.dxpe.com';
        '10.103.68' = 'hobbyepdm2.dxpe.com';
        '10.103.72' = 'shrdfs01.dxpe.com';
        '10.103.80' = 'hobbyepdm2.dxpe.com';
        '10.128.147' = 'holdfs01.dxpe.com';
        '10.88.0' = 'tyldfs01.dxpe.com';
        '10.94.0' = 'southbepdm1.dxpe.com';
        '10.96.240' = 'holdfs01.dxpe.com';
        '10.96.248' = 'holdfs01.dxpe.com'
    }
    
    # Hash table of install types
    $installTable = @{
        'A' = '';
        'B' = '2020_SP0.0_PDM_Editor_eDrawings';
        'C' = '2020_SP0.0_PDM_Viewer_eDrawings';
        'D' = '2020_SP0.0_SolidWorks';
        'E' = '2020_SP0.0_SolidWorks_PDM_Editor'
    }
    
    # Choose our install type
    $installName = $installTable[$InstallType]
    Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Install type: $installName"
    
    # Gather local IP addresses
    $localIPs = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'}).IPAddress
    
    # Look for a server match
    foreach ($ip in $localIPs)
    {
        $a,$b,$c,$d = $ip -split('\.')
        $subnet = "$a.$b.$c"
    
        if ($locationTable.Contains($subnet))
        {
            $serverName = $locationTable[$subnet]
            Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Discovered server: $serverName"
            break
        }
    }
    
    if (!($serverName))
    {
        Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value 'Unable to find a subnet/server match. Defaulting to houdfs08.dxpe.com'
        $serverName = 'houdfs08.dxpe.com'
    }
    # Create the download path
    $installPath = "\\$serverName\SW_Admin\$installName"
    
    # Invoke the install
    $exePath = "$installPath\64bit\sldim\sldim.exe"
    $xmlPath = "$installPath\64bit\AdminDirector.xml"
    Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Install path: $installPath"
    
    try
    {
        #Start-Process -FilePath $exePath -ArgumentList "/adminclient /new /source $xmlPath" -NoNewWindow -Wait
        Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Install complete. Please verify that it was successful."
    }
    catch
    {
        Add-Content -Path 'C:\windows\temp\SWInstall.log' -Value "Something went wrong."
    }
}