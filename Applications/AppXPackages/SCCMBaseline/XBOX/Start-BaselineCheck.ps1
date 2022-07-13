# Simple script for use in an SCCM basline to check for the presence of X-Box components on client devices

$oComponents = Get-AppxPackage | Where-Object {$_.Name -match 'xbox' -and $_.NonRemovable -eq $false}
if ($oComponents) {
    return $true
}

return $false