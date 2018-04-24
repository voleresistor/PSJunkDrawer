param
(
    [Parameter(Mandatory=$true)]
    [string]$InputCsv,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\temp\Copy-NetApp\New-ReplicatedMigrationFolder.log"
)

<#
    .Synopsis
    Create replication topologies for migrated shares.
    
    .Description
    Creates replication topology for each share in the input CSV.
    
    .Parameter InputCsv
    The CSV file containing settings for this script.

    .Parameter LogPath
    The location and name of the logfile.
    
    .Example
    New-ReplicatedMigrationFolder.ps1 -InputCsv c:\temp\migration.csv
    
    Creates a new replication topology for each share in the input CSV.
#>

# Include useful functions
. .\Include\UsefulFunctions.ps1

# Initialize log
Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message ' '
Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Begin New-ReplicatedMigrationFolder"

#Import CSV file
$CsvFile = Import-Csv -Path $InputCsv -Delimiter ','

foreach ($entry in $CsvFile)
{
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message ' '
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Share: $($entry.ShareName)"

    $PrimaryContentPath = $($entry.PrimaryDrive) + ":\" + $($entry.ParentFolder) + "\" + $($entry.ShareName)
    $ReplContentPath = $($entry.ReplDrive) + ":\" + $($entry.ParentFolder) + "\" + $($entry.ShareName)

    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Primary content path: $PrimaryContentPath"
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Replication content path: $ReplContentPath"

    #Create replication group topology
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Creating replication group: $($entry.DFSRGroupName) with folder $($entry.ShareName) and members $($entry.PrimaryServer), $($entry.ReplServer)"

    try
    {
        New-DfsReplicationGroup -GroupName "$($entry.DFSRGroupName)" -DomainName dxpe.com | `
            New-DfsReplicatedFolder -FolderName $($entry.ShareName) | `
            Add-DfsrMember -ComputerName $($entry.PrimaryServer),$($entry.ReplServer)
    }
    catch
    {
        Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Couldn't create replication group: $($entry.DFSRGroupName)" -Type 'Error'
        continue
    }

    # Create replication connection
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Create replication connection for group: $($entry.DFSRGroupName)"

    try
    {
        Add-DfsrConnection -GroupName "$($entry.DFSRGroupName)" -SourceComputerName $($entry.PrimaryServer) -DestinationComputerName $($entry.ReplServer)
    }
    catch
    {
        Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Couldn't create replication connection for group: $($entry.DFSRGroupName)" -Type 'Error'
        continue
    }

    # Define primary replication membership
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Define primary member $($entry.PrimaryServer) with replication path $PrimaryContentPath and stage size $($entry.StageSize)"

    try
    {
        Set-DfsrMembership -GroupName "$($entry.DFSRGroupName)" -FolderName $($entry.ShareName) -ContentPath $PrimaryContentPath `
            -ComputerName $($entry.PrimaryServer) -PrimaryMember $true -StagingPathQuotaInMB $($entry.StageSize) -Force
    }
    catch
    {
        Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Couldn't add primary member: $($entry.PrimaryServer)" -Type 'Error'
        continue
    }

    # Define replication partner
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Define replication member $($entry.ReplServer) with replication path $ReplContentPath and stage size $($entry.StageSize)"

    try
    {
        Set-DfsrMembership -GroupName "$($entry.DFSRGroupName)" -FolderName $($entry.ShareName) -ContentPath $ReplContentPath `
        -ComputerName $($entry.ReplServer) -StagingPathQuotaInMB $($entry.StageSize) -Force
    }
    catch
    {
        Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Couldn't add replication partner: $($entry.ReplServer)" -Type 'Error'
        continue
    }
}

# Update DFSR configs
Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Updating DFSR configuration from AD for replication members: $($entry.PrimaryServer), $($entry.ReplServer)"

try
{
    Update-DfsrConfigurationFromAD -ComputerName $($entry.PrimaryServer), $($entry.ReplServer)
}
catch
{
    Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Couldn't push DFSR configuration update." -Type 'Error'
}

Write-Log -LogPath $LogPath -Component 'New-ReplicatedMigrationFolder' -File 'New-ReplicatedMigrationFolder.ps1' -Message "Done"