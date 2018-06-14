param
(
    [Parameter(Mandatory=$true)]
    [string]$InputCsv,

    [Parameter(Mandatory=$true)]
    [ValidateSet('Create', 'Enable')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [switch]$RootShare,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\temp\Copy-NetApp\Set-NetAppMigrationTargets.log"
)

<#
    .Synopsis
    Create and enable DFS folder targets.
    
    .Description
    Create and enable multiple DFS folder targets using data from an input CSV file.
    
    .Parameter InputCsv
    The CSV file containing settings for this script.

    .Parameter Action
    Enable or Create targets. New targets are disabled upon creation in this script.

    .Parameter LogPath
    The location and name of the logfile.
    
    .Example
    Set-NetAppMigrationTargets.ps1 -InputCsv c:\temp\migration.csv -Action 'Create'
    
    Create disabled targets for all shares listed in the CSV.

    .Example
    Set-NetAppMigrationTargets.ps1 -InputCsv c:\temp\migration.csv -Action 'Enable'

    Enable targets for all shares listed in the CSV. This will fail if targets don't exist. Disables targets that reference \\10.128.18.248.
#>

# Include useful functions
. .\Include\UsefulFunctions.ps1

# Initialize log
Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message ' '
Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message 'Begin Set-NetAppMigrationTargets'

# Import CSV file
if (Test-Path -Path $InputCsv)
{
    Write-Log -LogPath $LogPath -Component 'Import-Csv' -File 'Set-NetAppMigrationTargets.ps1' -Message "Importing $InputCsv"
    $CsvFile = Import-Csv -Path $InputCsv -Delimiter ','
}
else
{
    Write-Log -LogPath $LogPath -Component 'Import-Csv' -File 'Set-NetAppMigrationTargets.ps1' -Message "Couldn't find $InputCsv" -Type 'Error'
    exit
}

# Log action to be performed
if ($Action -eq 'Create')
{
    Write-Log -LogPath $LogPath -Component 'Import-Csv' -File 'Set-NetAppMigrationTargets.ps1' -Message "Creating DFSN folder targets."
}
elseif ($Action -eq 'Enable')
{
    Write-Log -LogPath $LogPath -Component 'Import-Csv' -File 'Set-NetAppMigrationTargets.ps1' -Message "Enabling DFSN folder targets."
}

foreach ($entry in $CsvFile)
{
    Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message ' '
    Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Update DFS folder targets for share: $($entry.ShareName)"

    if ($($entry.DFSPath))
    {
        # Verify that DFS folder exists
        if (!(Get-DfsnFolder -Path $($entry.DFSPath)))
        {
            Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Couldn't find $($entry.DFSPath)" -Type 'Warning'
            continue
        }
        else
        {
            Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Found $($entry.DFSPath)"
        }
    
        # Create new targets
        if ($Action -eq 'Create')
        {
            # Define new targets
            if ($RootShare)
            {
                $PrimaryTarget = "\\" + $($entry.PrimaryServer) + "\" + $($entry.PrimaryFolder) + "\" + $($entry.ShareName)
                $ReplTarget = "\\" + $($entry.ReplServer) + "\" + $($entry.ReplFolder) + "\" + $($entry.ShareName)
            }
            else
            {
                $PrimaryTarget = "\\" + $($entry.PrimaryServer) + "\" + $($entry.ShareName)
                $ReplTarget = "\\" + $($entry.ReplServer) + "\" + $($entry.ShareName)
            }
        
            try
            {
                Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Adding $PrimaryTarget"
                New-DfsnFolderTarget -Path $($entry.DFSPath) -TargetPath $PrimaryTarget -State Offline
            }
            catch
            {
                Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Failed to add $PrimaryTarget" -Type 'Error'
                continue
            }
        
            try
            {
                Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Adding $ReplTarget"
                New-DfsnFolderTarget -Path $($entry.DFSPath) -TargetPath $ReplTarget -State Offline
            }
            catch
            {
                Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Failed to add $ReplTarget" -Type 'Error'
                continue
            }
        }
    
        # Enable targets
        if ($Action -eq 'Enable')
        {
            $FolderTargets = Get-DfsnFolderTarget -Path $($entry.DFSPath)
        
            # Toggle targets
            foreach ($t in $FolderTargets)
            {
                Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Found $($t.TargetPath) with state $($t.State)"
            
                if ($($t.TargetPath) -like '\\10.128.18.248*')
                {
                    try
                    {
                        Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Disabling $($t.TargetPath) in $($entry.DFSPath)"
                        Set-DfsnFolderTarget -Path $($entry.DFSPath) -TargetPath $($t.TargetPath) -State 'Offline'
                    }
                    catch
                    {
                        Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Failed to disable $($t.TargetPath) in $($entry.DFSPath)" -Type 'Error'
                    }
                }
                else
                {
                    try
                    {
                        Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Enabling $($t.TargetPath) in $($entry.DFSPath)"
                        Set-DfsnFolderTarget -Path $($entry.DFSPath) -TargetPath $($t.TargetPath) -State 'Online'
                    }
                    catch
                    {
                        Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Failed to enable $($t.TargetPath) in $($entry.DFSPath)" -Type 'Error'
                    }
                }
            }
        }
    }
    else
    {
        Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "No DFSPath entry. Skipping $($entry.ShareName)"
    }
}

Write-Log -LogPath $LogPath -Component 'NetApp Migration' -File 'Set-NetAppMigrationTargets.ps1' -Message "Done."