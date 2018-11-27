param
(
    [parameter(Mandatory=$true)]
    [string]$SourcePath,

    [parameter(Mandatory=$true)]
    [string]$DestPath,

    [parameter(Mandatory=$false)]
    [string]$Filter,

    [parameter(Mandatory=$false)]
    [switch]$Move
)

$SourceFile = Get-ChildItem -Path $SourcePath -Filter $Filter | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($move)
{
    Move-Item -Path $($SourceFile.FullName) -Destination $DestPath -Force
}
else
{
    Copy-Item -Path $($SourceFile.FullName) -Destination $DestPath -Force
}