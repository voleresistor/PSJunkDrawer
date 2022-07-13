# Simple script for use in an SCCM baseline to remove X-Box components from a device

$oComponents = Get-AppxPackage | Where-Object {$_.Name -match 'xbox' -and $_.NonRemovable -eq $false}

foreach ($c in $oComponents) {
    Remove-AppxPackage -Package $c
}
