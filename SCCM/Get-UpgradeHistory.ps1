#requires -Version 5.0

Param
(
    [array]$ComputerName
)

# Store collected data
class UpgradeHistory
{
    [string]$ComputerName

    [string]$SourceOS

    [string]$SourceEdition

    [string]$SourceBuild

    [string]$UpgradeDate
}

# Array of data objects
$UpgradeHistoryResults = @()

foreach ($c in $ComputerName)
{
    # Connect remote reg and get data on upgrade keys
    try
    {
        $RemoteReg = [Microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$c)
        $SetupKey = $RemoteReg.OpenSubKey('SYSTEM\\Setup')
        $UpgradeRecords = $SetupKey.GetSubKeyNames() | Where-Object -FilterScript {$_ -match 'Source OS'}
    }
    catch
    {
        # Create a record to record blank results
        $ClientUpgradeHistory = [UpgradeHistory]::new()
        $ClientUpgradeHistory.ComputerName = $c
        $ClientUpgradeHistory.SourceOS = 'Offline'

        # Add to array
        $UpgradeHistoryResults += $ClientUpgradeHistory
        Clear-Variable ClientUpgradeHistory

        # Continue execution with next target
        continue
    }

    # Record no data and continue if no records exist
    if (!($UpgradeRecords))
    {
        # Create a record to record blank results
        $ClientUpgradeHistory = [UpgradeHistory]::new()
        $ClientUpgradeHistory.ComputerName = $c
        $ClientUpgradeHistory.SourceOS = 'No upgrade data'

        # Add to array
        $UpgradeHistoryResults += $ClientUpgradeHistory
        Clear-Variable ClientUpgradeHistory

        # Continue execution with next target
        $RemoteReg.Close()
        continue
    }
    
    # Process all present upgrade keys
    foreach ($Record in $UpgradeRecords)
    {
        # Instantiate class and open upgrade key
        $ClientUpgradeHistory = [UpgradeHistory]::new()
        $CurrentRecord = $RemoteReg.OpenSubKey("SYSTEM\\Setup\\$Record")
        
        # Client name
        $ClientUpgradeHistory.ComputerName = $c

        # Upgrade date
        $Record -match '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' | Out-Null
        $ClientUpgradeHistory.UpgradeDate = $Matches[0]

        # Get source OS Name
        $ClientUpgradeHistory.SourceOS = $CurrentRecord.GetValue('ProductName')

        # Get source edition
        $ClientUpgradeHistory.SourceEdition = $CurrentRecord.GetValue('EditionID')

        # Get source build
        $ClientUpgradeHistory.SourceBuild = $CurrentRecord.GetValue('CurrentBuild')

        # Add collected data to final array
        $UpgradeHistoryResults += $ClientUpgradeHistory

        # Clear variables used in loop
        Clear-Variable ClientUpgradeHistory
    }

    Clear-Variable UpgradeRecords
    $RemoteReg.Close()
}

return $UpgradeHistoryResults