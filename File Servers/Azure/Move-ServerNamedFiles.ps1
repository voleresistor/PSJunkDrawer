function Move-ServerNamedFiles
{
    param
    (
        [string]$ServerName,

        [string]$Path = (Get-Location).Path,

        [string]$Destination
    )

    function New-RelativePath
    {
        param
        (
            [string]$Source,

            [string]$SourceRoot,

            [string]$Destination
        )

        # Update source root with escaped back slashes
        $SourceRoot = $SourceRoot -replace('\\', '\\')

        # replace source root with destination root
        return $Source -replace("$SourceRoot", "$Destination")
    }

    # Exit if folder doesn't exist
    if (!(Test-Path -Path $Destination -ErrorAction SilentlyContinue))
    {
        Write-Error -Message "Destination folder doesn't exist."
        return 1
    }

    # Also exit if folder isn't empty
    if ((Get-ChildItem -Path $Destination).Count -ne 0)
    {
        Write-Error -Message "Destination folder isn't empty."
        return 2
    }


    Get-ChildItem -Path $Path -Recurse -Filter "*-$ServerName*" | `

    ForEach-Object {
        $NewPath = "$(New-RelativePath -Source $($_.DirectoryName) -SourceRoot $Path -Destination $Destination)"

        if (!(Test-Path -Path $NewPath -ErrorAction SilentlyContinue))
        {
            New-Item -Path $NewPath -Force -ItemType Directory
        }

        Move-Item -Path $($_.FullName) -Destination $NewPath
    }
}