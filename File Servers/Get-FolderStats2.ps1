<#
    Slower than original Get-FolderStats - 36s vs 11s
#>
function Get-FolderStats
{
    param
    (
        [string]$Path
    )

    $size = 0
    $files = 0
    $folders = 0

    Get-ChildItem -Path $Path | ForEach-Object -Process {
        if ($_.PsIsContainer -eq $false)
        {
            $size += $_.Length
            $files ++
        }
        else
        {
            $folders ++
            $sub = Get-FolderStats -Path $_.FullName
            $files += $sub.Files
            $folders += $sub.Folders
            $size += $sub.RawSize
            Clear-Variable -Name sub
        }
    }

    # Decide how granularly to report the total size
    if ($size -lt 1048576)
    {
        $finalSize = "$('{0:N2}' -f ($size / 1kb)) kb"
    }
    elseif ($size -lt 1073741824)
    {
        $finalSize = "$('{0:N2}' -f ($size / 1mb)) mb"
    }
    else
    {
        $finalSize = "$('{0:N2}' -f ($size / 1gb)) gb"
    }

    $results = New-Object -TypeName psobject
    $results | Add-Member -MemberType NoteProperty -Name Size -Value $finalSize
    $results | Add-Member -MemberType NoteProperty -Name Files -Value $files
    $results | Add-Member -MemberType NoteProperty -Name Folders -Value $folders
    $results | Add-Member -MemberType NoteProperty -Name Path -Value $Path
    $results | Add-Member -MemberType NoteProperty -Name RawSize -Value $size

    return $results
}