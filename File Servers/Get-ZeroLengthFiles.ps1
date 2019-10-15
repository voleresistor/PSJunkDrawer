function Get-ZeroLengthFiles
{
    param
    (
        [string]$Path,

        [string]$LogPath,

        [string]$LogName = "zerolen-$(Get-Date -UFormat %M%d%y).tsv"
    )

    # Initialize
    $zerolen = @()
    if (!(Test-Path -Path "$LogPath\$LogName"))
    {
        New-Item -Path $LogPath -Name $LogName
    }

    # Get everything in $Path
    foreach ($f in Get-ChildItem -Path $Path -Attributes D,H,R,S,!D,!H,!R,!S)
    {
        # Recurse if folder
        if ($f.PsIsContainer)
        {
            Get-ZeroLengthFiles -Path $f.FullName -LogPath $LogPath -LogName $LogName
        }
        # Otherwise check for zero length
        else
        {
            # If zero length, create a custom object and add it to the pile
            if ($f.Length -eq 0)
            {
                $entry = New-Object -TypeName PSObject
                $entry | Add-Member -MemberType NoteProperty -Name FileName -Value $f.Name
                $entry | Add-Member -MemberType NoteProperty -Name FilePath -Value $f.Directory
                $entry | Add-Member -MemberType NoteProperty -Name LastWriteTimeUTC -Value $f.LastWriteTimeUtc
                $entry | Add-Member -MemberType NoteProperty -Name Owner -Value $((Get-Acl -Path $f.FullName).Owner)
                $zerolen += $entry

                Clear-Variable -Name entry
            }
        }
    }

    #foreach ($e in $zerolen)
    #{
    #    Add-Content -Path "$LogPath\$LogName" -Value "$($e.FileName)`t$($e.Owner)`t$($e.LastWriteTimeUtc)`t$($e.FilePath)"
    #}
    return $zerolen
}