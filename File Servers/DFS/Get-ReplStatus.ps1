param
(
    [parameter(
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [string[]]$ComputerName = "$env:computername",
    
    [switch]$List
)

begin
{
    $AllMembersList     = @()
    $AllMembersCount    = @()
}

process
{
    foreach ($target in $ComputerName)
    {
        $BackLog = Get-DfsrState -ComputerName $target
        
        if ($List)
        {
            $AllMembersList += $BackLog
        }
        else
        {
            $BackLogCount = New-Object -TypeName psobject
            $BackLogCount | Add-Member -MemberType NoteProperty -Name ComputerName -Value $target
            $BackLogCount | Add-Member -MemberType NoteProperty -Name InboundCount -Value (($BackLog | ?{$_.Inbound -eq 'True'}).Count)
            $BackLogCount | Add-Member -MemberType NoteProperty -Name OutboundCount -Value (($BackLog | ?{$_.Inbound -ne 'True'}).Count)
            $BackLogCount | Add-Member -MemberType NoteProperty -Name Total -Value (($BackLog).Count)
            $AllMembersCount += $BackLogCount
        }
    }
}

end
{
    if ($List)
    {
        return $AllMembersList | Select-Object PSComputerName,SourceComputerName,FileName,Path,Inbound,UpdateState
    }
    else
    {
        return $AllMembersCount
    }
}