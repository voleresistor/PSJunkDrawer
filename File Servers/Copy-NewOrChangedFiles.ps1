function Copy-NewOrChangedFiles
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$ReplicaPath,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$ResultLog,

        [Parameter(Mandatory=$true, Position=4)]
        [string]$ErrorLog
    )

    # Modify paths for regex use
    $srcmod = $SourcePath -replace("\\", "\\")

    foreach ($i in Get-ChildItem -Path $SourcePath)
    {
        #Modify source path to escape back slashes
        $mir = $($($i.FullName) -replace($srcmod, $ReplicaPath))
        Write-Progress -Activity "Copy new or changed files" -Status $($i.FullName)
        
        # If the current item is a folder
        if ($i.PsIsContainer)
        {
            if (!(Test-Path -Path $mir -ErrorAction SilentlyContinue))
            {
                Write-Host "Copying new folder $($i.FullName)"
                try
                {
                    #New-Item -Path $mir -Directory
                    continue
                }
                catch
                {
                    Add-Content -Path $ErrorLog -Value "Failed to create new folder $($i.FullName)"
                    continue
                }

                Add-Content -Path $ResultLog -Value "Created new folder $($i.FullName)"
            }

            # Recurse one directory deeper
            Copy-NewOrChangedFiles -SourcePath $($i.FullName) -ReplicaPath $mir -ResultLog $ResultLog -ErrorLog $ErrorLog
        }
        # Otherwise it's a file
        else
        {
            # File doesn't exist
            if (!(Test-Path -Path $mir -ErrorAction SilentlyContinue))
            {
                Write-Host "Copying new files $($i.FullName)"
                try
                {
                    #Copy-Item -Path $($i.FullName) -Destination $mir
                }
                catch
                {
                    Add-Content -Path $ErrorLog -Value "Failed to copy new file $($i.FullName)"
                    continue
                }

                Add-Content -Path $ResultLog -Value "Copied new file $($i.FullName)"
            }
            # File in source is newer than replica
            elseif ($i.LastWriteTimeUtc -gt $(Get-ChildItem -Path $mir).LastWriteTimeUtc)
            {
                Write-Host "Copying modified file $($i.FullName)"
                try
                {
                    #Copy-Item -Path $($i.FullName) -Destination $mir -Force
                }
                catch
                {
                    Add-Content -Path $ErrorLog -Value "Failed to copy modified file $($i.FullName)"
                    continue
                }

                Add-Content -Path $ResultLog -Value "Copied modified file $($i.FullName)"
            }
        }
    }
}