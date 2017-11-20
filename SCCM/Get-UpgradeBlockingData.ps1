param
(
    [string]
    $ComputerName = $env:COMPUTERNAME,

    [string]
    $DataPath = "$env:SystemDrive\`$WINDOWS.~BT\Sources\Panther",

    [string]
    $LogPath = "$DataPath\BlockingData.log"
)

# Write-Log function
function Write-Log
{
    param
    (
        [string]
        $Message
    )

    $date = Get-Date -UFormat "%m%d%y - %H:%M:%S"
    Write-Host $Message
    Add-Content -Path $LogPath -Value "$date >> $Message"
}

# Get-ScanResult function
function Get-ScanResult
{
    param
    (
        $WorkingFile
    )

    # Block scan class
    class BlockScan
    {
        [string]
        $BlockName

        [string]
        $BlockClass

        [string]
        $BlockType

        [string]
        $BlockMessage

        [string]
        $XmlName
    }
    
    $XmlData = $null
    [xml]$XmlData = Get-Content -Path $($WorkingFile.FullName)

    # Check Hardware items
    if ($XmlData.CompatReport.Hardware.HardwareItem)
    {
        foreach ($Hardware in $XmlData.CompatReport.Hardware.HardwareItem)
        {
            if ($Hardware.CompatibilityInfo.BlockingType -eq 'Hard')
            {
                # Instantiate and populate data class
                $FoundBlock = New-Object 'BlockScan'
                $FoundBlock.BlockName = $($Hardware.CompatibilityInfo.Title)
                $FoundBlock.BlockClass = 'Hardware'
                $FoundBlock.BlockType = $($HardWare.CompatibilityInfo.BlockingType)
                $FoundBlock.BlockMessage = $($Hardware.CompatibilityInfo.Message)
                $FoundBlock.XmlName = $($WorkingFile.Name)

                # Add object to overall array
                Write-Log -Message "$($FoundBlock.BlockName) - $($FoundBlock.BlockClass) - $($FoundBlock.BlockType) - '$($FoundBlock.BlockMessage)' - $($FoundBlock.XmlName)"
            }
        }
    }

    # Check devices
    if ($XmlData.CompatReport.Devices)
    {
        foreach ($Device in $XmlData.CompatReport.Devices.Device)
        {
            # Instantiate and populate data class
            $FoundBlock = New-Object 'BlockScan'
            $FoundBlock.BlockName = "$($Device.Manufacturer) $($Device.Model)"
            $FoundBlock.BlockClass = "Device: $($Device.Class)"
            $FoundBlock.BlockType = $($Device.CompatibilityInfo.BlockingType)
            $FoundBlock.BlockMessage = "$($Device.CompatibilityInfo.StatusDetail): $($Device.CompatibilityInfo.Message)"
            $FoundBlock.XmlName = $($WorkingFile.Name)

            # Add object to overall array
            Write-Log -Message "$($FoundBlock.BlockName) - $($FoundBlock.BlockClass) - $($FoundBlock.BlockType) - '$($FoundBlock.BlockMessage)' - $($FoundBlock.XmlName)"
        }
    }

    # Check Programs
    if ($XmlData.CompatReport.Hardware.HardwareItem)
    {

    }

    # Check driver packages
    if ($XmlData.CompatReport.DriverPackages)
    {
        foreach ($Driver in $XmlData.CompatReport.DriverPackages.DriverPackage)
        {
            if ($Driver.BlockMigration -eq 'True')
            {
                # Instantiate and populate data class
                $FoundBlock = New-Object 'BlockScan'
                $FoundBlock.BlockName = $($Driver.Inf)
                $FoundBlock.BlockClass = 'Driver'
                $FoundBlock.BlockType = $($Driver.BlockMigration)
                $FoundBlock.XmlName = $($WorkingFile.Name)

                # Add object to overall array
                Write-Log -Message "$($FoundBlock.BlockName) - $($FoundBlock.BlockClass) - $($FoundBlock.BlockType) - '$($FoundBlock.BlockMessage)' - $($FoundBlock.XmlName)"
            }
        }
    }
}

# ********************************************************
# Program
# ********************************************************

# Clear out old logs
if (Test-Path $LogPath)
{
    Move-Item -Path $LogPath -Destination "$LogPath.old" -Force
}

# Get list of XML files in DataPath
$XmlFiles = Get-ChildItem -Path $DataPath -Filter *.xml

# Parse each xml file
foreach ($Xml in $XmlFiles)
{
    Get-ScanResult -WorkingFile $Xml
}