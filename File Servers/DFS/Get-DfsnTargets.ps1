function Get-DfsnTargets
{
    param
    (
        [string]$DfsRoot,

        [string]$SearchString
    )

    $folders = Get-ChildItem -Path $DfsRoot -Directory

    foreach ($f in $folders)
    {
        if ($f.Attributes -like "*ReparsePoint*")
        {
            Get-DfsnFolderTarget -Path $($f.FullName) | Where-Object {$_.TargetPath -like "*$SearchString*"}
        }
        else
        {
            Get-DfsnTargets -DfsRoot $($f.FullName) -SearchString $SearchString
        }
    }
}