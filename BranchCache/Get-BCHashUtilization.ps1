function Get-BCHashUtilization {
    [Cmdletbinding()]
    param (
        
    )

    $hash = Get-BCHashCache

    $utilizationPct = [MATH]::Round(($($hash.CurrentActiveCacheSize) / $($hash.MaxCacheSizeAsNumberOfBytes)), 2)

    return $utilizationPct
}