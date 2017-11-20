function Get-TireDiameters
{
    <#
        .Synopsis
        Easily determine valid tire diameters.

        .Description
        Outputs data about percent differences in size and measured speed between a stock and a single or range of aftermarket tire diameters.

        .Parameter StockDiameter
        Stock diameter in inches.

        .Parameter Speed
        Speed to compare measured differences in MPH. Default: 45mph

        .Parameter TargetDiameter
        Target diameter to compare, if known.

        .Parameter DiameterRange
        Range to add/subtract from working diameter  if not supplying a TargetDiameter. Default: 0.5

        .Example
        Get-TireDiameters -StockDiameter 25

        Get speed and size difference of diameters from 24.5 to 25.5

        .Example
        Get-TireDiameters -StockDiameter 25 -TargetDiameter 25.3

        Get speed and size difference of only TargetDiameter.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [float]$StockDiameter,

        [Parameter(Mandatory=$false, Position=2)]
        [float]$Speed = 45,

        [Parameter(Mandatory=$false)]
        [float]$TargetDiameter,

        [Parameter(Mandatory=$false)]
        [float]$DiameterRange = 0.5,

        [Parameter(DontShow)]
        [float]$InchesInMile = 5280*12,

        [Parameter(Dontshow)]
        [float]$CmInKm = 100*1000
    )
    # TODO: Allow for conversion to metric?

    if ($TargetDiameter) # Behavior is slightly modified if we know what diameter we're using and just want to know how bad the difference is
    {
        $Results = New-Object -TypeName psobject
        $Results | Add-Member -MemberType NoteProperty -Name StockDiameter -Value $([math]::Round($StockDiameter,3))
        $Results | Add-Member -MemberType NoteProperty -Name TargetDiameter -Value $([math]::Round($TargetDiameter,3))
        $Results | Add-Member -MemberType NoteProperty -Name PercentDifference -Value $([math]::Round($((($CurrentDiameter / $StockDiameter) - 1.0) * 100.0),3))
        $Results | Add-Member -MemberType NoteProperty -Name StockSpeed -Value $([math]::Round($Speed,3))
        $Results | Add-Member -MemberType NoteProperty -Name TargetSpeed -Value $([math]::Round($($Speed + ($Speed * $($Results.PercentDifference / 100.0))),3))

        return $Results
    }
    else # If we don't know, we'll just output a table within a reasonable size range
    {
        # A parent object to hold the children
        $ResParent = @()

        [float]$CurrentDiameter = $StockDiameter - $DiameterRange
        while ($CurrentDiameter -lt $StockDiameter + $DiameterRange + 0.1)
        {
            $Results = New-Object -TypeName psobject
            $Results | Add-Member -MemberType NoteProperty -Name StockDiameter -Value $([math]::Round($StockDiameter,3))
            $Results | Add-Member -MemberType NoteProperty -Name TargetDiameter -Value $([math]::Round($CurrentDiameter,3))
            $Results | Add-Member -MemberType NoteProperty -Name PercentDifference -Value $([math]::Round($((($CurrentDiameter / $StockDiameter) - 1.0) * 100.0),3))
            $Results | Add-Member -MemberType NoteProperty -Name StockSpeed -Value $([math]::Round($Speed,3))
            $Results | Add-Member -MemberType NoteProperty -Name TargetSpeed -Value $([math]::Round($($Speed + ($Speed * $($Results.PercentDifference / 100.0))),3))

            $ResParent += $Results
            Clear-Variable -Name results # Clear $Results to ensure nothing silly happens between runs
            $CurrentDiameter += 0.1
        }

        return $ResParent
    }
}

<#
Example:
    PS C:\temp> Get-TireDiameters -StockDiameter 25.3 | ft

    StockDiameter TargetDiameter PercentDifference StockSpeed TargetSpeed
    ------------- -------------- ----------------- ---------- -----------
             25.3           24.8            -1.976         45      44.111
             25.3           24.9            -1.581         45      44.289
             25.3             25            -1.186         45      44.466
             25.3           25.1            -0.791         45      44.644
             25.3           25.2            -0.395         45      44.822
             25.3           25.3                 0         45          45
             25.3           25.4             0.395         45      45.178
             25.3           25.5             0.791         45      45.356
             25.3           25.6             1.186         45      45.534
             25.3           25.7             1.581         45      45.711
             25.3           25.8             1.976         45      45.889
#>