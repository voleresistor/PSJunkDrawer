function Recover-ConflictAndDeleted
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$MatchString,

        [Parameter(Mandatory=$true)]
        [string]$ShareSource,

        [Parameter(Mandatory=$false)]
        [string]$RestorePath
    )

    # Load manifest from $SourcePath
    [xml]$manifest = Get-Content -Path "$ShareSource\DfsrPrivate\ConflictAndDeletedManifest.xml"

    # Operate on files that match the $MatchString regex
    foreach ($f in ($manifest.ConflictAndDeletedManifest.Resource | Where-Object {$_.Path -match $MatchString}))
    {
        if ($RestorePath)
        {
            # Original name is hidden in the Path attribute of the file
            $originalName = ($f.Path -split("\\"))[-1]

            Write-Host "$($f.Path)`t-`t" -NoNewLine

            try
            {
                Copy-Item -Path "$ShareSource\DfsrPrivate\ConflictAndDeleted\$($f.NewName)" -Destination "$RestorePath\$originalName"
            }
            catch
            {
                Write-Host "FAILED" -ForegroundColor 'Red'
                Continue
            }

            Write-Host "RESTORED" -ForegroundColor 'Green'
        }
        else
        {
            # Just list potential restore candidates if $RestorePath wasn't specified
            Write-Host "$($f.Path)"
        }
    }

    # Remind user of restore path
    if ($RestorePath)
    {
        Write-Host "`r`nFiles were restored to: $RestorePath"
    }
}