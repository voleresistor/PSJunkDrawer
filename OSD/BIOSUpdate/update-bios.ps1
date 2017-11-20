param
(
    [string]$ComputerName = '.', # Only use this for testing. Script not equipped to handle remote BIOS upgrade
    [string]$SourcePath = '\\housccm04.dxpe.com\BIOSUpdate\',
    [string]$DestPath = 'C:\temp\BIOSUpdate'
)

# *******************************************************
# This try/catch block controls initial data collection
# without this info, the script cannot continue so all
# errors are treated as stop errors

$OldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try
{
    # Gather a few WMI queries
    $WmiComputerSystem = Get-WmiObject -Namespace 'root\cimv2' -Class 'Win32_ComputerSystem' -ComputerName $ComputerName
    $WmiComputerSystemProduct = Get-WmiObject -Namespace 'root\cimv2' -Class 'Win32_ComputerSystemProduct' -ComputerName $ComputerName
    $WmiOperatingSystem = Get-WmiObject -Namespace 'root\cimv2' -Class 'Win32_OperatingSystem' -ComputerName $ComputerName
    $WmiBios = Get-WmiObject -Namespace 'root\cimv2' -Class 'Win32_Bios' -ComputerName $ComputerName

    # Create some variables from these queries
    $Manufacturer = $WmiComputerSystem.Manufacturer
    $Model = $WmiComputerSystem.Model
    $LenovoModel = $WmiComputerSystemProduct.Version
    $OSArch = $WmiOperatingSystem.OSArchitecture
    $SMBIOSv = $WmiBios.SMBIOSBIOSVersion
    $BIOSv = $WmiBios.Version

    # Display gathered data
    Write-Host "Manufacturer: $Manufacturer"
    Write-Host "Model: $Model"
    Write-Host "Model (Lenovo): $LenovoModel"
    Write-Host "Architecture: $OSArch"
    Write-Host "BIOS Version: $BIOSv"
    Write-Host "SMBIOS Version: $SMBIOSv"
}
# Catch any error and end execution
catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

    Out-Host "An error ocurred and program execution will stop: " -ForegroundColor Red -NoNewline
    Out-Host $ErrorMessage -ForegroundColor Yellow
    exit 1
}

# Return ErrorActionPreference to default
$ErrorActionPreference = $OldEAP

# End data collection block
# *******************************************************

# Build path to correct BIOS Update
if($Manufacturer -eq 'LENOVO')
{
    $SourcePath += $OSArch + '\' + $Manufacturer + '\' + $LenovoModel
}
else
{
    $SourcePath += $OSArch + '\' + $Manufacturer + '\' + $Model
}

# Check if $SourcePath exists and get latest BIOS version or exit
if (Test-Path -Path $SourcePath)
{
    $LatestUpdate = ((Get-Content "$SourcePath\latest.txt" -Last 1) -Split ':')
    $Latest = $LatestUpdate[0]
    [datetime]$LatestDate = $LatestUpdate[1]
}
else
{
    Write-Host "No BIOS update path found for $Manufacturer $Model $LenovoModel"
    exit 0
}

Write-Host "Update source path: $SourcePath"
Write-Host "Latest BIOS: $Latest"
Write-Host "BIOS release date: $LatestDate"

if ($Manufacturer -eq 'LENOVO')
{
    $BIOSVersion = ($SMBIOSv -split ' ')[0]
}
elseif ($Manufacturer -eq 'Hewlett-Packard')
{
    if ($SMBIOSv -match ("F\.[0-9]{2}"))
    {
        $BIOSVersion = $Matches[0]
    }
    elseif ($SMBIOSv -match ("[0-9]{2}.[0-9]{2}"))
    {
        $BIOSVersion = $Matches[0]
    }
    else
    {
        Write-Host "Unable to determine BIOS version for $Manufacturer $Model"
        exit 0
    }
}
elseif ($Manufacturer -eq 'Dell Inc.')
{
    $BIOSVersion = $SMBIOSv
}
else
{
    Write-Host "Unable to determine BIOS version for $Manufacturer $Model"
    exit 0
}

if (!($BIOSVersion -eq $Latest))
{
    Write-Host "BIOS version $BIOSVersion not equal to latest $Latest!`r`nBegin update process!" -ForegroundColor Red

    # Create path for BIOS update files
    if (Test-Path -Path $DestPath)
    {
        Remove-Item $DestPath -Recurse -Force
    }
    New-Item $DestPath -ItemType Directory -Force | Out-Null

    # Copy update files
    Copy-Item -Path "$SourcePath\$Latest" -Destination $DestPath -Recurse
}
else
{
    Write-Host "BIOS Already up to date!"
    exit 0
}

# *******************************************************
# Run BIOS update script here
$UpdateScript = $DestPath + '\' + $Latest + '\doupdate.cmd'
$UpdateLog = $DestPath + '\UpdateLog-' + $Latest + '.txt'

Write-Host "Running update script: $UpdateScript"
Write-host "Saving log to: $UpdateLog"

$UpdateProcess = New-Object System.Diagnostics.Process
$UpdateProcess.StartInfo.FileName = $UpdateScript
$UpdateProcess.StartInfo.RedirectStandardOutput = $true
$UpdateProcess.StartInfo.UseShellExecute = $false

$UpdateProcess.Start() | Out-Null
#$UpdateProcess.WaitForExit()

# Wait for process to complete
$UpdateStart = Get-Date
while (!($UpdateProcess.HasExited))
{
    if (((Get-Date) - $UpdateStart).Minutes -ge 15)
    {
        Stop-Process -Id $UpdateProcess.Id -Force
    }
    Start-Sleep -Seconds 5
}


Add-Content -Value $UpdateProcess.StandardOutput.ReadToEnd() -Path $UpdateLog

if ($UpdateProcess.ExitCode -eq 0)
{
    Write-Host "Update completed successfully. A restart is required."
    exit 3010
}
else
{
    Write-Host "There was a problem with the BIOS update package."
    exit $UpdateProcess.ExitCode
}