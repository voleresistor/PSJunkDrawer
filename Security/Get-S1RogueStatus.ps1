function Get-S1RogueStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$IPList
    )

    $allResults = [System.Collections.ArrayList]@()
    $counter = 1

    Foreach ($ip in $IPList) {
        Write-Progress -Activity "Checking rogues list..." -Status "$counter/$($IPList.Count)" -CurrentOperation $ip -PercentComplete (($counter / $($IPList.Count)) * 100)
        $result = Test-Connection -ComputerName $ip -Count 1 -Quiet
        $dnsname = Resolve-DnsName $ip -ErrorAction SilentlyContinue
        $thisResult = @{
            'Address' = $ip
            'DNSName' = $($dnsname.NameHost)
            'Online' = $result
        }
        
        $resultObj = [pscustomobject]$thisResult
        $allResults.Add($resultObj)
        $counter++
    }

    return $allResults
}