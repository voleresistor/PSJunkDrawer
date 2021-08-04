function Start-RegistrySearch {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$SearchRoot,

        [Parameter(Mandatory=$True)]
        [string]$SearchString
    )

    #Write-Verbose "Gathering properties for key $SearchRoot"

    # Get properties of the current key
    $kProps = Get-ItemProperty -LiteralPath $SearchRoot
    $results = @()
    foreach ($p in $kProps) {
        if ($p -like $SearchString) {
            $results += $p
            Write-Verbose "Found match at $($p.PSChildName)"
        }
    }

    # Collect subkeys
    $subKeys = Get-ChildItem -LiteralPath $SearchRoot
    Write-Verbose "Found $($subKeys.Count) subkeys under $SearchRoot"

    # Recursive call for each subkey
    foreach ($sKey in $subKeys) {
        Write-Verbose "Searching $($sKey.PSChildName)..."
        $keyPath = $sKey.Name -replace ('HKEY_LOCAL_MACHINE', 'hklm:')
        $results += Start-RegistrySearch -SearchRoot $KeyPath -SearchString $SearchString
    }

    return $results
}