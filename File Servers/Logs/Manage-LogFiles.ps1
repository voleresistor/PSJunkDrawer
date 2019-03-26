param
(
    [string]$LogPath = "\\dxpe.com\dfsa\Logs\Azure\Snapshots\$env:ComputerName",
    [int]$MaxAge = 30
)

$logs = Get-ChildItem -Path $LogPath

foreach ($l in $logs)
{
    if ($l.LastWriteTime -lt (Get-Date).AddDays(-$MaxAge))
    {
        Remove-Item -Path $l.FullName -Force
    }
}