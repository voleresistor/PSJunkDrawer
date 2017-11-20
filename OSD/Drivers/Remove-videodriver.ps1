# Define log files
$LogFile = 'C:\windows\temp\removeVideoDrivers.log'
$StdOutFile = 'C:\Windows\temp\RemoveVideoDriversStdOut.log'
$DriverList = 'C:\Windows\temp\driverlist.log'
$StdVGAInst = 'C:\Windows\temp\InstallVGADriver.log'

# Begin logging
Add-Content -Value "Started $(Get-Date)" -Path $LogFile
Add-Content -Value "Getting list of third party video drivers." -Path $LogFile

# Gather driver list. Dump it into a file and read that file into the variable for
# consistency with usage of Start-Process below
Start-Process -FilePath "$env:windir\System32\pnputil.exe" -ArgumentList "-e" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $DriverList
$Drivers = Get-Content -Path $DriverList
$RemoveCount = 0

# Iterate through the list, looking for Display drivers
for ($i = 0; $i -lt $($Drivers.Count); $i++)
{
    # Uninstall Display drivers using pnputil.exe
    if ($($Drivers[$i]) -match 'Display')
    {
        # Some string editing shenannigans are required here to extract the .inf names
        $RemoveDriver = $($Drivers[$i-2] -split '            ')[1]
        Write-Host "Removing driver $RemoveDriver..."
        Add-Content -Value "Removing driver $RemoveDriver..." -Path $LogFile

        # Uninstall the driver and pipe the output into a file, then pipe the contents of that file back into
        # our log file. It's necessary to do it this way so we can append the stdout contents to the log
        Start-Process -FilePath "$env:windir\System32\pnputil.exe" -ArgumentList "-f -d $RemoveDriver" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $StdOutFile
        $Result = Get-Content -Path $StdOutFile
        Add-Content -Value $Result -Path $LogFile

        Clear-Variable RemoveDriver
        $RemoveCount++
    }
}

# Finalize the removal
Add-Content -Value "Removed $RemoveCount video driver(s)." -Path $LogFile

# Install standard MS VGA driver
Add-Content -Value 'Installing MS Standard VGA Driver.' -Path $LogFile
Start-Process -FilePath "$env:windir\System32\pnputil.exe" -ArgumentList "-i -a c:\Windows\inf\display.inf" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $StdVGAInst
$Result = Get-Content -Path $StdVGAInst
Add-Content -Value $Result -Path $LogFile

# Finalize the log
Add-Content -Value "Completed $(Get-Date)" -Path $LogFile