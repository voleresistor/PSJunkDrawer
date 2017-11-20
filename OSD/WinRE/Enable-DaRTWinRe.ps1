<#
    Solution: OSD
    Purpose: Ensure that custom DaRT recovery image is configured for use.
    Version: 1.0 - 02/20/17

    Author: Andrew Ogden
    Email: andrew.ogden@dxpe.com
#>

param
(
    [string]$RecoveryDriveLabel = 'Recovery',
    [string]$DriveLetter = 'R',
    [string]$RecoveryPath = "Recovery\WindowsRE"
)

#Function to make writing to BDD.log straightforward
function TSLogWrite
{
    param
    (
        [string]$Value,
        [string]$Component = 'ZTIPowerShell',
        [string]$Context,
        [string]$Type = '1',
        [string]$Thread,
        [string]$File = 'Enable-DaRTWinRE',
        [string]$Log = $LogFile
    )

    $LogDate = Get-Date
    $FormattedDate = "$("{0:00}" -f ($LogDate.Month))-$("{0:00}" -f ($LogDate.Day))-$($LogDate.Year)"
    $FormattedTime = $LogDate.TimeOfDay -match ("\d{2}:\d{2}:\d{2}.\d{3}")
    $FormattedTime = $Matches[0]
    $FormattedTime = $FormattedTime + "+000"

    Add-Content -Path $Log -Value "<![LOG[$Value]LOG]!><time=`"$FormattedTime`" date=`"$FormattedDate`" component=`"$Component`" context=`"$Context`" type=`"$Type`" thread=`"$Thread`" file=`"$File`">"
}

#Function to handle catching and logging errors
function CatchErrors
{
    param
    (
        [string]$ErrorMessage,
        [string]$FailedTask
    )

    TSLogWrite -Value $FailedTask
    TSLogWrite -Value $ErrorMessage
    exit 1
}

#Load ComObject containing TS environment variables
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

#Get OSDCOMPUTERNAME variable from TSEnv
$OSDComputerName = $tsenv.Value("OSDCOMPUTERNAME")
$DeployRoot = $tsenv.Value("DEPLOYROOT")
$ScriptRoot = "$DeployRoot\Scripts"

# Set up logging
$LogLocation = $tsenv.Value("SLSHAREDYNAMICLOGGING")
$LogFile = $LogLocation + '\BDD.log'

#Collect some basic data
$osIsServer = $tsenv.Value("ISSERVER")
$osVer = $tsenv.Value("OSCURRENTVERSION")
$osVer = $osVer -split '\.'
$osMajor = $osVer[0]
$osMinor = $osVer[1]
TSLogWrite -Value "Computer OS version: $osVer"

#Determine path to RE image based on OS ver
if ($osIsServer -eq 'False')
{
    TSLogWrite "Computer OS type: Workstation"
    switch ($osMajor)
    {
        10
        {
            TSLogWrite "Host is Windows 10."
            $winREPath = "$ScriptRoot\DXP\WinRE\Win10"
        }
        6
        {
            TSLogWrite "Host is Windows 7."
            $winREPath = "$ScriptRoot\DXP\WinRE\Win7"
        }
        default
        {
            TSLogWrite "ERROR: Unable to determine OS version."
            exit 1
        }
    }
}
else
{
    TSLogWrite "Computer OS type: Server"
    switch ($osMajor)
    {
        6
        {
            switch ($osMinor)
            {
                1
                {
                    TSLogWrite "Host is Windows Server 2008 R2."
                    $winREPath = "$ScriptRoot\DXP\WinRE\Win7"
                }
                3
                {
                    TSLogWrite "Host is Windows Server 2012 R2."
                    $winREPath = "$ScriptRoot\DXP\WinRE\Win7"
                }
            }
        }
        10
        {
            TSLogWrite "Host is Windows Server 2016."
            $winREPath = "$ScriptRoot\DXP\WinRE\Win10"
        }
        default
        {
            TSLogWrite "ERROR: Unable to determine OS version."
            exit 1
        }
    }
}

#Disable default recovery image
TSLogWrite 'Disable default recovery image...'
try
{
    Start-Process -FilePath "$env:windir\System32\REAgentc.exe" -ArgumentList '/disable' -NoNewWindow -PassThru -Wait -ErrorAction Stop
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to disable default recovery image."
}

#Mount recovery drive
$RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel
if (!($RecoveryDrive))
{
    TSLogWrite 'ERROR: No recovery drive found. Was this machine an MDT build?'
    exit 1
}

#Assign a letter to the drive if it doesn't have one
if ($RecoveryDrive.DriveLetter -eq $null)
{
    #Assign the first available letter
    TSLogWrite -Value 'Adding a letter to the recovery drive...'
    try
    {
        Get-Partition -Volume $RecoveryDrive | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
        $RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel

        #Artificial wait timer to give WMI time update after changes
        while ($RecoveryDrive.DriveLetter -eq $null)
        {
            Start-Sleep -Seconds 1
            $RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel
        }
    }
    catch
    {
        CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to assign a letter to recovery drive."
    }
    TSLogWrite -Value 'Done'
    
    #$RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel
    TSLogWrite -Value "Recovery drive path: $($RecoveryDrive.Path)"
    TSLogWrite -Value "Recovery drive size: $($RecoveryDrive.Size)"
    TSLogWrite -Value "Recovery drive letter: $($RecoveryDrive.DriveLetter)"

    #Once we have a drive letter, change it to the one we want to use
    # NOTE: Why???
    <#if ($RecoveryDrive.DriveLetter -ne "$DriveLetter")
    {
        TSLogWrite -Value "Remapping Recovery drive to letter $DriveLetter`:\"
        try
        {
            Set-Partition -DriveLetter $($RecoveryDrive.DriveLetter) -NewDriveLetter $DriveLetter -ErrorAction Stop
            $RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel

            #Artificial wait timer to give WMI time update after changes
            while ($RecoveryDrive.DriveLetter -ne "$DriveLetter")
            {
                Start-Sleep -Seconds 1
                $RecoveryDrive = Get-Volume -FileSystemLabel $RecoveryDriveLabel
            }
        }
        catch
        {
            CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to reassign drive letter."
        }
        $RecoveryDrive = Get-Volume -FileSystemLabel 'Recovery'
        TSLogWrite -Value "New recovery drive letter: $($RecoveryDrive.DriveLetter):\"
    }#>
}

# Instead of building it in params, why not set the folder names and populate the disk letter now
$RecoveryPath = "$($RecoveryDrive.DriveLetter)`:\$RecoveryPath"

#Remove old folder on recovery drive
if (Test-Path -Path $RecoveryPath -ErrorAction SilentlyContinue)
{
    TSLogWrite -Value 'Recovery path already exists. Deleting old data...'
    try
    {
        Remove-Item -Path $RecoveryPath -Recurse -Force -ErrorAction Stop
    }
    catch
    {
        CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to delete old recovery path."
    }
    TSLogWrite -Value 'Done'
}

#Create new folder on recovery drive
TSLogWrite 'Creating new recovery path folder...'
try
{
    New-Item -Path $RecoveryPath -ItemType Directory -Force -ErrorAction Stop
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to create new recovery path folder."
}
TSLogWrite -Value 'Done'

#Copy recovery image
TSLogWrite -Value "Copying WinRE image from $winREPath to $RecoveryPath"
try
{
    Copy-Item -Path "$winREPath\winre.wim" -Destination $RecoveryPath -Force -ErrorAction Stop
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to copy WinRE image."
}
TSLogWrite -Value 'Done'

#assign recovery image
$PartitionNum = $(Get-Partition -Volume $RecoveryDrive).PartitionNumber
$RecoveryString = "\\?\GLOBALROOT\device\harddisk0\partition$PartitionNum\Recovery\WindowsRE"
TSLogWrite -Value "Configuring path to new recovery image: $RecoveryString"
try
{
    Start-Process -FilePath "$env:windir\System32\REAgentc.exe" -ArgumentList "/setreimage /path $RecoveryString" -NoNewWindow -PassThru -Wait -ErrorAction Stop

    #Wait for settings change to sink in
    Start-Sleep -Seconds 3
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to update WinRE location."
}
TSLogWrite -Value 'Done'

#Enable recovery
TSLogWrite -Value 'Enabling new recovery image...'
try
{
    Start-Process -FilePath "$env:windir\System32\REAgentc.exe" -ArgumentList '/enable' -NoNewWindow -PassThru -Wait -ErrorAction Stop

    #Wait for settings change to sink in
    Start-Sleep -Seconds 3
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to enable WinRE."
}
TSLogWrite -Value 'Done'

#Hide recovery drive
TSLogWrite -Value 'Hiding recovery partition...'
try
{
    Get-Partition -Volume $RecoveryDrive | Remove-PartitionAccessPath -AccessPath "$($RecoveryDrive.DriveLetter)`:\" -ErrorAction Stop
}
catch
{
    CatchErrors -ErrorMessage $_.Exception.Message -FailedTask "Failed to hide recovery partition."
}
TSLogWrite -Value 'Done'

#Exit with no errors
TSLogWrite -Value "Recovery drive configuration complete."
exit 0