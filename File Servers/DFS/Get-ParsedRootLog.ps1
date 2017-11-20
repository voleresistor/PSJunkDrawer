[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true, Position=1)]
    [string]$LogRoot,

    [Parameter(DontShow)]
    [switch]$UseLatest
)

#Get yesterday's log unless not
if ($UseLatest)
{
    $TargetLog = (Get-ChildItem $LogRoot | Sort-Object -Descending -Property LastWritetime)[0]
}
else
{
    $TargetLog = (Get-ChildItem $LogRoot | Sort-Object -Descending -Property LastWritetime)[1]
}

#Gather the raw data and prepare an array to hold the sub reports
$LogObj = Import-Csv -Delimiter ',' -Path $($TargetLog.FullName)
$Reports = @()

#Number of times a source hits a root
$SourceByRoot = @()

foreach ($entry in $LogObj)
{
    $RootEntries = $SourceByRoot | Where-Object ?{$_.Root -eq $($entry[1])}
    foreach ($rootEntry in $RootEntries)
    {
        if ($rootEntry.Source -eq $entry[3])
        {
            $rootEntry.count++
        }
    }
    if (($SourceByRoot.Source -notcontains $entry[3]) -and ($SourceByRoot.Root -notcontains $entry[1]))
    {

    }
    $root = New-Object -TypeName psobject
    $root | Add-Member -MemberType NoteProperty -Name Root -Value $entry[1]
    $root | Add-Member -MemberType NoteProperty -Name Share -Value $entry[1]
    $root | Add-Member -MemberType NoteProperty -Name Source -Value $entry[1]

}

#Number of hits per root

