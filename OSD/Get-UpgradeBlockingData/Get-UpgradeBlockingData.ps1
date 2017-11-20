# Get-UpgradeBlockingData.ps1
# 
# Author: Andrew Ogden
#
# Parse XML files left behind by Windows 10 setup.exe when running compatibility prechecks
# prior to upgrade. These files are challenging for humans to read, but are organized in a relatively
# simple format that can be easily parsed by scripts.
#
# Changes:
#       06/01/17 - Convert from PowerShell 5 classes to older style PSObjects for custom data objects
#
#
param
(
    [string]
    $DataPath = "$env:SystemDrive\`$WINDOWS.~BT\Sources\Panther",

    [string]
    $LogPath = "$DataPath\BlockingData.log"
)

# Write-Log function
# Both outputs data to standard out as well as into a log file
function Write-Log
{
    param
    (
        [string]
        $Message
    )

    # Timestamp log entries
    $date = Get-Date -UFormat "%m%d%y - %H:%M:%S"
    Write-Host $Message
    Add-Content -LiteralPath $LogPath -Value "$date >> $Message"
}

# Get-ScanResult function
# Parse the specified XML file and present an array of objects containing
# data on upgrade blocks
function Get-ScanResult
{
    param
    (
        $WorkingFile
    )

    # Block scan class - Currently disabled due to compatibility issues
    #class BlockScan
    #{
    #    [string]
    #    $BlockName
#
    #    [string]
    #    $BlockClass
#
    #    [string]
    #    $BlockType
#
    #    [string]
    #    $BlockMessage
#
    #    [string]
    #    $XmlName
    #}
    
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
                #$FoundBlock = New-Object 'BlockScan'
                #$FoundBlock.BlockName = $($Hardware.CompatibilityInfo.Title)
                #$FoundBlock.BlockClass = 'Hardware'
                #$FoundBlock.BlockType = $($HardWare.CompatibilityInfo.BlockingType)
                #$FoundBlock.BlockMessage = $($Hardware.CompatibilityInfo.Message)
                #$FoundBlock.XmlName = $($WorkingFile.Name)
                $FoundBlock = New-Object -TypeName PSObject
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockName -Value $($Hardware.CompatibilityInfo.Title)
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockClass -Value 'Hardware'
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockType -Value $($HardWare.CompatibilityInfo.BlockingType)
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockMessage -Value $($Hardware.CompatibilityInfo.Message)
                $FoundBlock | Add-Member -MemberType NoteProperty -Name XmlName -Value $($WorkingFile.Name)

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
            #$FoundBlock = New-Object 'BlockScan'
            #$FoundBlock.BlockName = "$($Device.Manufacturer) $($Device.Model)"
            #$FoundBlock.BlockClass = "Device: $($Device.Class)"
            #$FoundBlock.BlockType = $($Device.CompatibilityInfo.BlockingType)
            #$FoundBlock.BlockMessage = "$($Device.CompatibilityInfo.StatusDetail): $($Device.CompatibilityInfo.Message)"
            #$FoundBlock.XmlName = $($WorkingFile.Name)
            $FoundBlock = New-Object -TypeName PSObject
            $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockName -Value "$($Device.Manufacturer) $($Device.Model)"
            $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockClass -Value "Device: $($Device.Class)"
            $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockType -Value $($Device.CompatibilityInfo.BlockingType)
            $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockMessage -Value "$($Device.CompatibilityInfo.StatusDetail): $($Device.CompatibilityInfo.Message)"
            $FoundBlock | Add-Member -MemberType NoteProperty -Name XmlName -Value $($WorkingFile.Name)

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
                #$FoundBlock = New-Object 'BlockScan'
                #$FoundBlock.BlockName = $($Driver.Inf)
                #$FoundBlock.BlockClass = 'Driver'
                #$FoundBlock.BlockType = $($Driver.BlockMigration)
                #$FoundBlock.XmlName = $($WorkingFile.Name)
                $FoundBlock = New-Object -TypeName PSObject
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockName -Value $($Driver.Inf)
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockClass -Value 'Driver'
                $FoundBlock | Add-Member -MemberType NoteProperty -Name BlockType -Value $($Driver.BlockMigration)
                $FoundBlock | Add-Member -MemberType NoteProperty -Name XmlName -Value $($WorkingFile.Name)

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
if (Test-Path -LiteralPath $LogPath)
{
    Move-Item -LiteralPath $LogPath -Destination "$LogPath.old" -Force
}

# Get list of XML files in DataPath
$XmlFiles = Get-ChildItem -LiteralPath $DataPath -Filter *.xml

# Parse each xml file
foreach ($Xml in $XmlFiles)
{
    Get-ScanResult -WorkingFile $Xml
}