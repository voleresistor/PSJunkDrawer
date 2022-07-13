function Start-BCCachePrune {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Hash', 'Data')]
        [string]$CacheType = 'Data',

        [ValidateRange(0,100)]
        [float]$ClearPct = 1.0
    )

    if ($CacheType -eq 'Hash') {
        $cachePct = Get-BCHashCache
        $utilizationPct = [MATH]::Round(($($cachePct.CurrentActiveCacheSize) / $($cachePct.MaxCacheSizeAsNumberOfBytes)), 2)
    }
    elseif ($CacheType -eq 'Data') {
        $cachePct = Get-BCDataCache
        $utilizationPct = [MATH]::Round(($($cachePct.CurrentActiveCacheSize) / $($cachePct.MaxCacheSizeAsNumberOfBytes)), 2)
    }
    else {
        Write-Error "No cache type specified. Please use -CacheType [Hash | Data] to specify."
    }

    $ClearPct = [Math]::Round(($ClearPct / 100), 2)
    Write-Verbose "BranchCache $CacheType cache at $($utilizationPct * 100)% capacity."

    if ($utilizationPct -ge $ClearPct) {
        Write-Verbose "Clearing BC cache"
        Clear-BCCache -WhatIf
    }
    else {
        Write-Verbose "BC cache is OK"
    }
}