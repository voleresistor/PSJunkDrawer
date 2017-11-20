#region Get-DFSRStats
function Get-DFSRStats
{
    <#
        .Synopsis
        Gather DFSR health stats from WMI.
        
        .Description
        Collect statistics about DFSR health including staging space in use and replication updates dropped.
        
        .Parameter ComputerName
        Name of target computer. Defaults to localhost.
        
        .Parameter ReplicationGroupName
        String to search for in replication group name. This can contain wildcards.
        
        .Example
        Get-DFSRStats -ComputerName dfs-01.domain.com
        
        Get formatted DFSR stats from specified DFS server.
    #>
    param
    (
        [string]$ComputerName = "$env:ComputerName",
        [string]$ReplicationGroupName
    )
    
    function Get-Size($iNum)
    {
        if (($iNum / 1tb) -gt 1)
        {
            $Formatted = "{0:N2}" -f ($iNum / 1tb)
            $Final = $Formatted + " TB"
        }
        elseif (($iNum / 1gb) -gt 1)
        {
            $Formatted = "{0:N2}" -f ($iNum / 1gb)
            $Final = $Formatted + " GB"
        }
        else
        {
            $Formatted = "{0:N2}" -f ($iNum / 1mb)
            $Final = $Formatted + " MB"
        }
        
        return $Final
    }
    
    $ReplicationGroups = Get-CimInstance -ClassName 'Win32_PerfFormattedData_dfsr_DFSReplicatedFolders'` -ComputerName $computerName
    
    $RepGroups = @()
    
    foreach ($Group in $ReplicationGroups)
    {
        $DFSRObj = New-Object -TypeName PSObject
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $($Group.PSComputerName)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'GroupName' -Value $($Group.Name)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceGenerated' -Value (Get-Size -iNum $Group.ConflictBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceCleaned' -Value (Get-Size -iNum $Group.ConflictBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceUsed' -Value (Get-Size -iNum $Group.ConflictSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceGenerated' -Value (Get-Size -iNum $Group.DeletedBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceCleaned' -Value (Get-Size -iNum $Group.DeletedBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceUsed' -Value (Get-Size -iNum $Group.DeletedSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceGenerated' -Value (Get-Size -iNum $Group.StagingBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceCleaned' -Value (Get-Size -iNum $Group.StagingBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceUsed' -Value (Get-Size -iNum $Group.StagingSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'UpdatesDropped' -Value $($Group.UpdatesDropped)
        
        $RepGroups += $DFSRObj
    }
    
    if (!($RepGroups | ?{$_.GroupName -like "$ReplicationGroupName`*"}))
    {
        return $RepGroups
    }
    else
    {
        return $RepGroups | Where-Object {$_.GroupName -like "$ReplicationGroupName`*"}
    }
}
<#
    C:\> Get-DFSRStats
    
    ComputerName           : dfs-01.domain.com
    GroupName              : ReplGroup-{z69tb0ym-576v-a8c3-1rsc-7qzjnkqgei8h}
    ConflictSpaceGenerated : 8.17 MB
    ConflictSpaceCleaned   : 0.00 MB
    ConflictSpaceUsed      : 8.17 MB
    DeletedSpaceGenerated  : 3.12 GB
    DeletedSpaceCleaned    : 0.00 MB
    DeletedSpaceUsed       : 3.12 GB
    StagingSpaceGenerated  : 1.09 TB
    StagingSpaceCleaned    : 1.01 TB
    StagingSpaceUsed       : 159.76 GB
    UpdatesDropped         : 0
#>
#endregion