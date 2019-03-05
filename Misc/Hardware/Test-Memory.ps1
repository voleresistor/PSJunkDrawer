function Test-Memory
{
    # From: https://www.petri.com/display-memory-usage-powershell
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = "$env:ComputerName"
    )

    $os = Get-CimInstance -ClassName win32_OperatingSystem -ComputerName $ComputerName
    $pctFree = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2)

    if ($pctFree -ge 45)
    {
        $Status = "OK"
    }
    elseif ($pctFree -ge 15)
    {
        $Status = "Warning"
    }
    else
    {
        $Status = "Critical"
    }

    $resultObj = New-Object -TypeName psobject
    $resultObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
    $resultObj | Add-Member -MemberType NoteProperty -Name MemoryTotal -Value $([math]::Round(($os.TotalVisibleMemorySize / 1mb), 2))
    $resultObj | Add-Member -MemberType NoteProperty -Name MemoryFree -Value $([math]::Round(($os.FreePhysicalMemory / 1mb), 2))
    $resultObj | Add-Member -MemberType NoteProperty -Name PercentInUse -Value $(100 - $pctFree)
    $resultObj | Add-Member -MemberType NoteProperty -Name Status -Value $Status

    return $resultObj
}