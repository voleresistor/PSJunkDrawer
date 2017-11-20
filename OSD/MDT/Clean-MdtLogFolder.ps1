param (
    [string]$Path = '\\houdfs02.dxpe.com\mdtlogs$',
    [int]$Age = '7'
)

$agedFolders = Get-ChildItem -Path $Path -Recurse | ?{$_.LastWriteTime -lt $((Get-Date).AddDays(-$Age))}

foreach ($folder in $agedFolders) {
    if (Get-ChildItem -Path $folder.FullName | ?{$_.LastWriteTime -lt $((Get-Date).AddDays(-$Age))}) {
        Remove-Item $folder.FullName -Force -Recurse
        if (Test-Path -Path $($folder.FullName)) {
            Write-Host "Couldn't delete $($folder.FullName)"
        }
    }
}