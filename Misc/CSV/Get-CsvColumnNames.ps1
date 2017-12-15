function Get-CsvColumnNames
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({Test-Path -Path $_ -Type Leaf})]
        [string]$FileName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$Delimiter
    )
    $csv = Import-Csv -Path $FileName -Delimiter $Delimiter
    return ($csv | Get-Member | Where-Object {$_.MemberType -eq 'NoteProperty'}).Name
}