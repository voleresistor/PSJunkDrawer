param (
    [string]$computerList,
    [string]$logPath
)

$computers = @(Get-Content $computerList)

Function logWrite ($message) {
    $time = (Get-Date -uFormat %T)
    Add-Content -Path $logPath -Value "$message"
}

logWrite -message "#ComputerName, #ClientVersion, #EPEnabled"

foreach ($c in $computers){
    $client = (Get-CMDevice -Name $c)
    $ver = $client.ClientVersion
    $eps = $client.EPEnabled
    logWrite -message "$c, $ver, $eps"
    Write-Host "$c"
    if ($ver){
        Write-Host "Client Version: " -NoNewline
        Write-Host $ver
        Write-Host "EP Enabled: " -NoNewline
        if ($eps){
            Write-Host $eps
        } else {
            Write-Host "False"
        }
    } else {
        Write-Host "Not a client."
    }
}