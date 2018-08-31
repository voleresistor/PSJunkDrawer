function DfsnRecurse
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$FolderName
    )

    $rootResult = @()
    $folderRes = Get-DfsnFolder -Path $FolderName -ErrorAction SilentlyContinue

    if (!$folderRes)
    {
        foreach ($f in (Get-ChildItem -Path $FolderName -Attributes D))
        {
            $rootResult += DfsnRecurse -FolderName $($f.FullName)
        }
    }
    else
    {
        $rootResult += $folderRes
    }

    return $rootResult
}

function Get-DfsnDump
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string[]]$DFSNFolderNames,

        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile = "C:\temp\dfsndump - $(Get-Date -Format '%M-%d-%y').csv"
    )

    # Check that file doesn't already exist
    if (Test-Path -Path $OutputFile)
    {
        $res = Read-Host "The file at $OutputFile already exists. OK to delete? (y/n)"
        if ($res -eq 'y')
        {
            Remove-Item -Path $OutputFile -Force
        }
        else
        {
            Write-Host "Please remove $OutputFile and re-run this script."
            exit
        }
    }

    # Get all DFSN roots
    $roots = Get-DfsnRoot -Domain $DomainName

    # Create empty array to store folder target objects
    $folderTargets = @()

    foreach ($fn in $DFSNFolderNames)
    {
        # Build current working root name
        $rootName = "\\$DomainName\$fn"

        # Verify that given root exists in domain
        if (!($roots.Path -contains "$rootName"))
        {
            Write-Host "Can't find $rootName" -ForegroundColor Yellow
            continue
        }
        else
        {
            Write-Host "Found $rootName" -ForegroundColor Green
        }

        # Create an array to store all the folder we query out of a root
        $dfsnFolders = @()

        # Recursively gather all DFSN folders from the given root
        foreach ($f in (Get-ChildItem "$rootName" -Attributes D))
        {
            $x = DfsnRecurse -FolderName $f.FullName
            $dfsnFolders += $x
        }

        # Collect all Online targets for each root
        foreach ($df in $dfsnFolders)
        {
            $y = Get-DfsnFolderTarget -Path $df.Path | Where-Object {$_.State -eq 'Online'}
            $folderTargets += $y
        }
    }

    # Create new csv file
    Add-Content -Value 'DFS Path,Target Path' -Path $OutputFile

    # Populate the csv file
    foreach ($e in $folderTargets)
    {
        $path = $($e.Path)
        # Strip some admin paths to make the result more readable
        $target = $($e.TargetPath) -replace ('10.128.18.248', 'hou-cf-02')
        $target = $target -replace ('Departments_DFS\$', 'Departments')
        Add-Content -Value "$path,$target" -Path $OutputFile
    }

    # return results and path to CSV
    Write-Host "Output file written to $OutputFile"
    return $folderTargets
}