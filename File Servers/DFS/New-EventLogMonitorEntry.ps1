function New-EventLogMonitorEntry
{
    <#
    .SYNOPSIS
    Generate simple CSV log entries based on Windows Event log entries.

    .DESCRIPTION
    Generate CSV logs based on Windows event log entries. Can be used to generate metrics on how often a particular event is logged or the source of certain events.

    .PARAMETER LogFullName
    Full name of the Windows event log being inspected. this parameter is required. Ex: 'Microsoft-Windows-DFSN-Server/Operational'

    .PARAMETER LogId
    Windows event log ID of the particular event being monitored. This parameter is required.

    .PARAMETER LogPath
    The folder or UNC path to the storage folder for the output log. This parameter is required.

    .PARAMETER LogFileName
    The name of the output log file. This will be created if it doesn't exist. Default: EvtMon-MMDDYY.csv

    .PARAMETER MatchTable
    A hashtable of value names and regex patterns to attempt to match from the event log.

    .EXAMPLE
    New-EventLogMonitorEntry.ps1 -LogFullName 'Microsoft-Windows-DFSN-Server/Operational' -LogId 501 -LogPath 'C:\temp'

    Generate a record of the ocurrences of LogId 501 in the DFSN Operational event log. This will only record the times entries with this ID are created.

    .EXAMPLE
    New-EventLogMonitorEntry.ps1 -LogFullName 'Microsoft-Windows-DFSN-Server/Operational' -LogId 501 -LogPath 'C:\temp' -MatchTable@{'Root'='(?<=\\)[\w|-]{1,}(?=\\)';'Share'='(?<=\\)([\w|&|_]{1,}){1,}(?= from client with)';'Client'='(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))'}

    Similar to Example 1, but also uses the regex hashtable to gather the root, share, and client hostname included in the Windows event log entry.

    .NOTES
    Originally generated with a very specific purpose and didn't always translate well back into a generalized function.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$LogFullName, #Example: 'Microsoft-Windows-DFSN-Server/Operational'

        [Parameter(Mandatory=$true, Position=2)]
        [int]$LogId, #Example: 501

        [Parameter(Mandatory=$true, Position=3)]
        [ValidateScript({Test-Path -Path $_ -PathType 'Container'})]
        [string]$LogPath, #Example: "\\dxpe.com\dfsa\DFS-Backups\ConsolidationRoots\"
        #[string]$LogPath = "C:\temp\"

        [Parameter(Mandatory=$false)]
        [string]$LogFileName = "EvtMon-$(Get-Date -UFormat %d%m%y).csv",

        [Parameter(Mandatory=$false)]
        [hashtable]$MatchTable
        #example: {'Root'='(?<=\\)[\w|-]{1,}(?=\\)';'Share'='(?<=\\)([\w|&|_]{1,}){1,}(?= from client with)' ;'Client'='(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))'}
    )

    # Build our logging path
    if ($LogPath[-1] -match "\\")
    {
        $LogFile += "$LogPath$LogFileName"
    }
    else
    {
        $LogFile += "$LogPath\$LogFileName"
    }

    # Gather the latest matching event log entry
    $latestLog = Get-WinEvent -FilterHashtable @{LogName=$LogFullName; ID=$LogId} | Select-Object -First 1

    $OutTable = @{} #New hashtable to store discovered data
    foreach ($key in $MatchTable.Keys)
    {
        if ($latestLog.Message -match $MatchTable[$key])
        {
            #:siren::siren:Here is a gross hack to resolve IP addresses to hostnames:siren::siren:
            if ($Matches[0] -match '(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))')
            {
                $client = [System.Net.Dns]::GetHostByAddress($Matches[0]).HostName
                $OutTable.Add($key, $client)
            }
            else
            {
                $OutTable.Add($key, $Matches[0])
            }
        }
        else
        {
            $OutTable.Add($key, '')
        }
    }

    $EntryValue = ($latestLog.TimeCreated).ToString()
    foreach ($e in $OutTable.Keys)
    {
        $EntryValue += ",$($OutTable[$e])"
    }

    Add-Content -Value $EntryValue -Path $LogFile
}