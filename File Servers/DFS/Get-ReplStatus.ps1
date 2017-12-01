function Get-ReplStatus
{
    <#
    .SYNOPSIS
    Quickly gather DFS replication status.
    
    .DESCRIPTION
    Get a count of backlogged files on each given DFSR server. Can also get a full listing of files in backlogs.
    
    .PARAMETER ComputerName
    An array of computernames to check.
    
    .PARAMETER List
    Get a complete listing of backlogged files instead of just a count.
    
    .EXAMPLE
    Get-ReplStatus -ComputerName DFSServer01,DFSServer02 -List

    Get a complete listing of the backlogs on DFSServer01 and DFSServer02.
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$false)]
        [switch]$List
    )

    $Results = @()

    foreach ($c in $ComputerName)
    {
        $BackLog = Get-DfsrState -ComputerName $c -ErrorAction SilentlyContinue
        if ($List)
        {
            $Results += $BackLog
        }
        else
        {
            $BackLogCount = New-Object -TypeName psobject
            $BackLogCount | Add-Member -MemberType NoteProperty -Name ComputerName -Value $c
            $BackLogCount | Add-Member -MemberType NoteProperty -Name InboundCount -Value (($BackLog | Where-Object {$_.Inbound -eq 'True'}).Count)
            $BackLogCount | Add-Member -MemberType NoteProperty -Name OutboundCount -Value (($BackLog | Where-Object {$_.Inbound -ne 'True'}).Count)
            $BackLogCount | Add-Member -MemberType NoteProperty -Name Total -Value (($BackLog).Count)
            $Results += $BackLogCount
        }
    }

    return $Results
}