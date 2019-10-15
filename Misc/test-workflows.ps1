$start = Get-Date

$computers = @(
    'DXPELT1235','DXPELT1157','DXPELT1199','DXPELT1213','DXPELT1224','DXPELT1245','DXPELT1265',
    'DXPELT1296','DXPELT1308','DXPELT1318','DXPELT1383','DXPELT1390','DXPELT1444','DXPELT1446',
    'DXPELT1461','DXPELT1469','DXPELT1474','DXPELT1503','DXPELT1504','DXPELT1511','DXPELT1512',
    'DXPELT1515','DXPELT1516','DXPELT1517','DXPEPC1402','DXPEPC1489A','DXPEPC1519','DXPEPC1527',
    'DXPEPC1653','DXPEPC1708','DXPEPC1764','DXPEPC1775','DXPEPC1787','DXPEPC1813','DXPEPC1842',
    'DXPEPC1935','DXPEPC2204','DXPEPC2233','DXPEPC2235','DXPEPC2238','DXPEPC2263','DXPEPC2282',
    'DXPEPC2363','DXPEPC2364','DXPEPC2394','DXPETB04','DXPETB16','DXPETB19','DXPETB27','DXPETB29',
    'DXPETB32','DXPETB33','DXPETB45','DXPETB46','DXPETB48','DXPETB49','LT745','LT751','PC692',
    'ROBSURFACE','W10X64-01'
)

workflow TestWorkflow {
    foreach -parallel -throttlelimit 8 ($c in $computers) {
        $DnsRecordsObj = Resolve-DnsName -Name $c
        foreach ($entry in $dnsRecord | ?{$_.IP4Address -ne $null}) {
            $DnsRecordsObj = New-Object -TypeName System.Object
            $DnsRecordsObj | Add-Member -Type NoteProperty -Name IPAddress -Value $($entry.IP4Address)
            $DnsRecordsObj | Add-Member -Type NoteProperty -Name Name -Value $($entry.Name)
            $RecordList += $DnsRecordsObj
            #Clear-Variable -Name DnsRecordsObj,entry
        }
    }
}

$RecordList = @()

TestWorkflow
$RecordList

$end = Get-Date
$runtime = $end - $start

Write-host "Run time: $runtime"