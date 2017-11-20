param(
    [string]$ComputerList,
    [switch]$BytesFromServer,
    [switch]$BytesFromCache,
    [switch]$BytesServed
)

# Create custom hashtable object to store data
$ColCounters = @()
$PCs = (Get-Content -Path $ComputerList)
$Sort = $null

if ($BytesFromServer){
    $Sort = "BytesFromServer"
}elseif ($BytesFromCache){
    $Sort = "BytesFromCache"
}else{
    $Sort = "BytesServed"
}

Function Read-Counters ($Counter, $CounterName){
    $CounterData = Get-counter "\\$c$Counter" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
    $StrippedCounterData = $CounterData.Readings -replace '.* :', ''
    $StrippedCounterData = $StrippedCounterData / 1MB
    $StrippedCounterData = "{0:N2}" -f $StrippedCounterData
    
    $ObjCounters | Add-Member -MemberType NoteProperty -Name $CounterName -Value "$StrippedCounterData MB"
}

foreach ($c in $PCs){
    # Populate custom object with collected data
    $ObjCounters = New-Object System.Object
    $ObjCounters | Add-Member -MemberType NoteProperty -Name ComputerName -Value $c

    Write-Host "Getting Branch Cache performance counters from " -NoNewline
    Write-Host "$c" -ForegroundColor DarkCyan

    Read-Counters -Counter "\BranchCache\Retrieval: Bytes from cache" -CounterName "BytesFromCache"
    Read-Counters -Counter "\BranchCache\Retrieval: Bytes from server" -CounterName "BytesFromServer"
    Read-Counters -Counter "\BranchCache\Retrieval: Bytes Served" -CounterName "BytesServed"

    # Add object to hastable
    $Script:ColCounters += $ObjCounters
}

$ColCounters | Sort-Object $Sort -Descending