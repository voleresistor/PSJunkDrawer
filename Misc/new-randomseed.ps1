function Get-RandomSeed {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Salt,

        [Parameter(Mandatory=$false)]
        [int32]$runTime = 5000
    )

    begin {
        # Load forms assembly to access mouse location
        try {
            [system.reflection.assembly]::loadWithPartialName('system.windows.forms') | out-null
        }
        catch {
            Write-Error "Failed to load required assemblies.`r`n$($_.Exception.Message)"
            break
        }

        # Initialize some variables
        $start = (Get-Date)
        $valArray = @()
        [int64]$total = 0
    }
    process {
        # Grab mouse position over the run time
        while ((New-TimeSpan -Start $start -End (Get-Date)).TotalMilliseconds -lt $runTime) {
            Write-Progress -Activity 'Tracking mouse.' -Status 'Move your mouse randomly to generate a random seed.' `
                -SecondsRemaining ((5000 - (New-TimeSpan -Start $start -End (Get-Date)).TotalMilliseconds) / 1000)
            $valArray += [math]::abs((Get-Date).ticks / ([math]::pow(([System.Windows.Forms.Cursor]::Position).X, 2)) `
                / ([math]::pow(([System.Windows.Forms.Cursor]::Position).Y, 2))).toint32($null)
            start-sleep -Milliseconds (Get-Random -Maximum 100 -Minimum 1)
        }

        foreach ($val in $valArray) {
            $total += $val
        }

        $final = (Get-Date).Ticks / [math]::pow(($total / $valArray.Count), (Get-Random -Minimum 1.01 -Maximum 1.99))

        while ($final -gt 2147483647) {
            $final = $final / (Get-Random -Minimum 1.01 -Maximum 1.99)
        }

        return $final.ToInt32($null)
    }
}