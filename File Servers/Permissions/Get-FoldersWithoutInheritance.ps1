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

    # Get directories in the given path
    Get-ChildItem -Path $Path -Directory | Foreach-Object -Process {
        # If recursive, run on each folder we discovered above
        if ($Recurse)
        {
            Get-FoldersWithoutInheritance -Path $_.FullName -Recurse
        }

        # This is the actual test for inheritance. If AreAccessRulesProtected is True,
        # inheritance has been disabled
        if ((Get-Acl -Path $($_.FullName)).AreAccessRulesProtected)
        {
            return $_.FullName
        }
    }
}