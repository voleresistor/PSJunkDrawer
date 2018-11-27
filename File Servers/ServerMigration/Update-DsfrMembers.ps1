param
(
    [string]$NewMemberName,

    [string]$MigrateSource,

    $Group,

    [string]$DomainName,

    [string]$RootPath
)

Add-DfsrMember -GroupName $($Group.GroupName) -ComputerName $NewMemberName -DomainName $DomainName

foreach ($Member in ($Group))
{
    Add-DfsrConnection -GroupName $($Group.GroupName) -SourceComputerName $($Member.ComputerName) `
        -DestinationComputerName $NewMemberName -DomainName $DomainName
    
    if ($($Member.ComputerName) -eq $MigrateSource)
    {
        $ContentPath = $RootPath + "\" + ($($Member.ContentPath) -split ("\\"))[-1]
    }
}

Set-DfsrMembership -GroupName $($Group.GroupName) -FolderName $($Group.FolderName) -ComputerName $NewMemberName `
    -ContentPath $ContentPath -DomainName $DomainName -StagingPathQuotaInMB $($Group.StagingPathQuotaInMB)[0] -Force