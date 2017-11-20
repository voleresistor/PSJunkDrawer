Param (
    [string]$source  = $(throw "-source and -dest required"),
    [string]$dest    = $(throw "-source and -dest required"),
    [string]$csvpath = "C:\scripts\files.csv"
)

If (Test-Path $csvpath) {
    Rename-Item -Path $csvpath -NewName ("{0}.{1}.txt" -f $csvpath, (get-random).tostring())
}

'' | select 'Source', 'Destination' | Export-Csv $csvpath -NoTypeInformation

Get-ChildItem $source -File |
ForEach-Object {"$($_.fullname),$dest\$($_.name)"} |
Out-File -Filepath $csvpath -Encoding ascii -Append

Import-Csv $csvpath |
Start-BitsTransfer -Asynchronous -RetryInterval 60 -Priority Low

While ($false -eq $false) { # lol
    Clear-Host ; "last update $(get-date)"
    Get-BitsTransfer |
    Where-Object { $_.jobstate -ne 'transferred'} |
    select jobid, jobstate,
    @{Label="percent Complete"; EXPRESSION={($_.BytesTransferred/$_.BytesTotal*100)} }

    If (Get-BitsTransfer | Where-Object {$_.jobstate -eq 'transferred'}) {
        break
    }

    sleep 10   
}
Get-BitsTransfer |
% { "Job id {0} transfered {1} in {2} total minutes" -f
$_.jobid, $_.bytesTransferred,
[int](New-TimeSpan -Start $_.CreationTime -End $_.TransferCompletionTime).totalMinutes }

Get-BitsTransfer | Complete-BitsTransfer