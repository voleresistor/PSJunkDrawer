function Get-FoldersWithoutInheritance
{
    <#
    .SYNOPSIS
    Find list of folders with inheritance disabled.

    .DESCRIPTION
    Checks the ACL on child folders to locate any that have no inherited permissions.

    .Parameter Path
    The path to check for subfolders without inheritance.

    .Parameter Recurse
    Recurse into all child folders.
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path,

        [Parameter(Mandatory=$false, Position=2)]
        [switch]$Recurse
    )

    # Storage array
    $noInheritance = @()

    # Select recursion
    if ($Recurse)
    {
        $folderList = Get-ChildItem -Path $Path -Recurse -Directory
    }
    else
    {
        $folderList = Get-ChildItem -Path $Path -Directory
    }

    # Locate the non-inherited folders
    foreach ($f in $folderList)
    {
        if (((Get-Acl -Path $($f.FullName)).Access.IsInherited) -notcontains 'True')
        {
            $noInheritance += $f.FullName
        }
    }

    return $noInheritance
}