function Start-RegistrySearch {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$SearchRoot,

        [Parameter(Mandatory=$True)]
        [string]$SearchString
    )

    #Write-Verbose "Gathering properties for key $SearchRoot"
    $skipChars = @(
        '.',
        '/'
    )

    # Get properties of the current key
    $thisKey = Get-Item -LiteralPath $SearchRoot
    $kProps = $thisKey.GetValueNames()
    $results = @()
    foreach ($p in $kProps) {
        $thisVal = $thisKey.GetValue($p)
        if ($thisVal -match $SearchString) {
            $thisResult = [PSCustomObject]@{
                Name = $($thisKey.Name) -replace ('HKEY_LOCAL_MACHINE', 'hklm:')
                ValueName = $p
                Value = $thisVal
            }
            $thisResult
            Write-Verbose "Found match at $($p.PSChildName)"
        }
        Clear-Variable thisVal
    }

    # Collect subkeys
    $subKeys = $thisKey.GetSubkeyNames()
    Write-Verbose "Found $($subKeys.Count) subkeys under $SearchRoot"

    # Recursive call for each subkey
    foreach ($sKey in $subKeys) {
        if ($skipChars -contains $sKey) {
            continue
        }
        $subkeyPath = "$(($thisKey.Name) -replace ('HKEY_LOCAL_MACHINE', 'hklm:'))\$sKey"
        if ($skey -match $SearchString) {
            $thisResult = [PSCustomObject]@{
                Name = $subkeyPath
                ValueName = ''
                Value = ''
            }
            $thisResult
            Write-Verbose "Found match at $subkeyPath"
        }
        Write-Verbose "Searching $subkeyPath..."
        $keyPath = $sKey.Name -replace ('HKEY_LOCAL_MACHINE', 'hklm:')
        Write-Progress -Activity 'Registry search' -Status $subkeyPath
        Start-RegistrySearch -SearchRoot $subkeyPath -SearchString $SearchString
    }

    #return $results
}