function Get-BCDataUtilization {
    [Cmdletbinding()]
    param (
        
    )

    $data = Get-BCdataCache

    $utilizationPct = [MATH]::Round(($($data.CurrentActiveCacheSize) / $($data.MaxCacheSizeAsNumberOfBytes)), 2)

    return $utilizationPct
}