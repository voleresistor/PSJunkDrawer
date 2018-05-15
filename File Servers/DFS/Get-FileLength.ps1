function Get-FileLength
{
    <#
    .SYNOPSIS
    Return length of the largest or smallest files in MB.
    
    .DESCRIPTION
    Get length of an arbitrary number of the largest or smallest files, returned in MB.
    
    .PARAMETER Path
    Path to the share beaing measured

    .PARAMETER FileCount
    Number of files to measure.

    .PARAMETER CountType
    Count smallest or largest files. Default: Largest
    
    .EXAMPLE
    Get-FileLenth -Path C:\temp
    
    .NOTES
    Originally written to aid in determining proper staging area size for DFS replication.
    #>

    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path,

        [Parameter(Mandatory=$false, Position=2)]
        [int]$FileCount = 10,

        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet('Largest', 'Smallest')]
        [string]$CountType = 'Largest'
    )

    # Convert length in bytes to human readable numbers
    function ConvertLength
    {
        param
        (
            [System.Int64]$Length
        )

        if ($Length -lt 1048576)
        {
            $size = "{0:N2}" -f $($Length / 1kb)
            $unit = 'KB'
        }
        elseif ($Length -lt 1073741824)
        {
            $size = "{0:N2}" -f $($Length / 1mb)
            $unit = 'MB'
        }
        elseif ($Length -lt 1099511627776)
        {
            $size = "{0:N2}" -f $($Length / 1gb)
            $unit = 'GB'
        }
        else
        {
            $size = "{0:N2}" -f $($Length / 1tb)
            $unit = 'TB'
        }

        return "$size $unit"
    }

    # Save file lengths here
    [System.Int64]$i = 0

    # Save custom objects here
    $Results = @()

    if (Test-Path -Path $Path -ErrorAction SilentlyContinue)
    {
        # Collect data with a neat little piped one-liner that's very fast
        if ($CountType -eq 'Smallest')
        {
            $ten = Get-ChildItem -Path $Path -Recurse | `
                Sort-Object -Property Length | `
                Select-Object -First $FileCount
        }
        else
        {
            $ten = Get-ChildItem -Path $Path -Recurse | `
                Sort-Object -Property Length -Descending | `
                Select-Object -First $FileCount
        }

        foreach ($f in $ten)
        {
            # Create new objects and add them to our results array
            $x = New-Object -TypeName psobject
            $x | Add-Member -MemberType NoteProperty -Name Name -Value $($f.FullName)
            $x | Add-Member -MemberType NoteProperty -Name Size -Value $(ConvertLength -Length $($f.Length))
            $Results += $x
            Clear-Variable x

            $i += $($f.Length)
        }
    }

    $x = New-Object -TypeName psobject
    $x | Add-Member -MemberType NoteProperty -Name Name -Value 'Total'
    $x | Add-Member -MemberType NoteProperty -Name Size -Value $(ConvertLength -Length $i)
    $Results += $x

    return $Results
}