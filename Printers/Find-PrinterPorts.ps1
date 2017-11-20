param (
    [string]$Port, #name or number of port to find
    [string]$ListPath #path to tesxt file with list of port names to search
)

if ($ListPath){
    $Port = @(Get-Content $ListPath)
}

Clear-Host
Write-Host "`r`nGetting port lists from all known servers..." -NoNewline

$ServerPorts = @(
    (Get-PrinterPort -ComputerName hdqprn01);
    (Get-PrinterPort -ComputerName dxpprn1);
    (Get-PrinterPort -ComputerName dxpprn3); 
    (Get-PrinterPort -ComputerName dxpprn4);
    (Get-PrinterPort -ComputerName dxpprn5);
    (Get-PrinterPort -ComputerName dxpprnmws)
)

Write-Host "Done" -ForegroundColor Green
Write-Host "Scanning server port lists for ports..." -NoNewline

foreach ($p in $Port){
    $ServerPorts | Where-Object {$_.Name -like "*$p*"}
    #if ($portmatch){
    #    Write-Host "`r`n$p found on server $($portmatch.Computername)" -NoNewline
    #} else {
    #    Write-Host "`r`n$p not found." -NoNewline
    #}
    #$portmatch = $null
}

Write-Host "`r`nDone!`r`n"