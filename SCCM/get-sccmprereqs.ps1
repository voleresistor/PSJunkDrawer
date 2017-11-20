param (
    [array]$computers,
    [array]$files
)

foreach ($c in $computers) {
    $msi = Get-Item -Path "\\$c\c$\Windows\System32\msi.dll"
    $bits = Get-Item -Path "\\$c\c$\Windows\System32\qmgr.dll"

    Write-Host "$c"
    Write-Host "MSI: " -NoNewline
    if ($msi.VersionInfo.ProductVersion -lt 3.1.4000.2435){
        Write-Host "$($msi.VersionInfo.ProductVersion)" -ForegroundColor Red
    } else {
        Write-Host "$($msi.VersionInfo.ProductVersion)" -ForegroundColor Green
    }
    Write-Host "BITS: " -NoNewline
    if ($bits.VersionInfo.ProductVersion -lt 6.7.0000.0000){
        Write-Host "$($bits.VersionInfo.ProductVersion)`r`n`r`n" -ForegroundColor Red
    } else {
        Write-Host "$($bits.VersionInfo.ProductVersion)`r`n`r`n" -ForegroundColor Green
    }
}