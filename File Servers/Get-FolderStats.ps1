<#
    Faster than rewrite Get-FolderStats - 11s vs 36s
#>
function Get-FolderStats
{
    param
    (
        [string]$Path,
        [switch]$RawSize
    )

    $size = 0
    $files = 0
    $folders = 0

    Get-ChildItem -Path $Path -Recurse | ForEach-Object {
        $size += $_.Length
        if ($_.PSIsContainer -eq $true)
        {
            $folders ++
        }
        else
        {
            $files ++
        }
    }

    # Decide how granularly to report the total size
    if ($RawSize)
    {
        $finalSize = $size
    }
    else
    {
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
    }

    $results = New-Object -TypeName psobject
    $results | Add-Member -MemberType NoteProperty -Name Size -Value $finalSize
    $results | Add-Member -MemberType NoteProperty -Name Files -Value $files
    $results | Add-Member -MemberType NoteProperty -Name Folders -Value $folders
    $results | Add-Member -MemberType NoteProperty -Name Path -Value $Path

    return $results
}