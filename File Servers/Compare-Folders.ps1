function Compare-Folders
{
    <#
    .SYNOPSIS
    Compare folders.

    .DESCRIPTION
    Compare file hashes for files in a pair of folders to ensure that folders are identical.

    .PARAMETER Folder1
    The reference folder.

    .PARAMETER Folder2
    The difference folder.

    .PARAMETER Print
    Change behavior to return the mismatched files paths instead of count.

    .NOTES
    Program returns negative values for internal errors and positive values for counts of mismatched files.
    -1 - Can't access folder
    -3 - Folders have different file counts

    Compiled with help from the following page:
    https://mcpmag.com/articles/2016/04/14/contents-of-two-folders-with-powershell.aspx
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Folder1,

        [Parameter(Mandatory=$true)]
        [string]$Folder2,

        [Parameter(Mandatory=$false)]
        [switch]$Print
    )

    # Check that both paths exist and we can access them
    Write-Verbose "Checking access to both folders..."
    if ((!(Test-Path -Path $Folder1 -ErrorAction SilentlyContinue)) -or (!(Test-Path -Path $Folder2 -ErrorAction SilentlyContinue)))
    {
        Write-Verbose "One or both folders don't exist or we can't access them."
        return -1
    }
    Write-Verbose "Folder access OK."

    # Get contents of folders
    Write-Verbose "Getting the contents of $Folder1..."
    $f1 = Get-ChildItem -Path $Folder1 -Recurse

    Write-Verbose "Getting the contents of $Folder2..."
    $f2 = Get-ChildItem -Path $Folder2 -Recurse

    # Check file counts
    if ($f1.Count -eq $f2.Count)
    {
        Write-Verbose "Both folders have the same number of files."
        # Calculate hashes for every file
        Write-Verbose "Calculating hashes for each file in $Folder1..."
        $f1_hash = @()
        foreach ($f in $f1)
        {
            Write-Progress -Activity "Calculating hashes for $Folder1" -Status $($f.FullName) -PercentComplete $(($f1.IndexOf($f) / $f1.Count) * 100)
            $f1_hash += Get-FileHash -Path $f.FullName
        }

        Write-Verbose "Calculating hashes for each file in $Folder2..."
        $f2_hash = @()
        foreach ($f in $f2)
        {
            Write-Progress -Activity "Calculating hashes for $Folder2" -Status $($f.FullName) -PercentComplete $(($f2.IndexOf($f) / $f2.Count) * 100)
            $f2_hash += Get-FileHash -Path $f.FullName
        }
    }
    else
    {
        Write-Verbose "Folders have different file counts."
        return -3
    }

    # Compare the hashes
    $diffs = (Compare-Object -ReferenceObject $f1_hash -DifferenceObject $f2_hash -Property Hash -PassThru).Path

    if ($Print)
    {
        return $diffs
    }
    return $diffs.Count
}