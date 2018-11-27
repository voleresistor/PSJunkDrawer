function Remove-Oldfiles
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path,

        [Parameter(Mandatory=$true, Position=2)]
        [int]$AgeInDays
    )

    # Check that path is accessible
    if (!(Test-Path -Path $Path -ErrorAction SilentlyContinue))
    {
        Write-Error "Can't access $Path"
        return -1
    }

    # Walk all the files
    foreach ($f in (Get-ChildItem -Path $Path -Recurse))
    {
        # Delete file if older than $AgeInDays
        if ($f.LastWriteTime -lt $((Get-Date).AddDays(-$AgeInDays)))
        {
            Write-Verbose "Deleting $($f.FullName)"
            Remove-Item $f.FullName -Force
        }
    }
}

#Remove-OldFiles -Path 'C:\temp\testpath' -AgeInDays 7