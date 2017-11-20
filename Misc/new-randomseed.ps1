$runTime = 5000

$start = (Get-Date)
$valArray = @()
$ErrorActionPreference = 'SilentlyContinue'
[int64]$total = 0

while ((New-TimeSpan -Start $start -End (Get-Date)).TotalMilliseconds -lt $runTime)
{
    $valArray += [math]::abs((Get-Date).ticks / ([math]::pow(([System.Windows.Forms.Cursor]::Position).X, 2)) / ([math]::pow(([System.Windows.Forms.Cursor]::Position).Y, 2))).toint32($null)
    start-sleep -Milliseconds (Get-Random -Maximum 10 -Minimum 1)
}

foreach ($val in $valArray)
{
    $total += $val
}

$final = (Get-Date).Ticks / [math]::pow(($total / $valArray.Count), 1.25)

while ($final -gt 2147483647)
{
    $final = $final / 2
}

$final.ToInt32($null)
