function Remove-CcmHwInventory
{
    param
    (
        [array]$ComputerName
    )

    foreach ($c in $ComputerName)
    {
        if ((Test-NetConnection -ComputerName $c -WarningAction SilentlyContinue -ErrorAction SilentlyContinue).PingSucceeded -eq 'True')
        {
            Write-Host "Attempting to delete hardware inventory data from " -NoNewline
            Write-Host $c -ForegroundColor Cyan

            $HwInvRecord = Get-WmiObject -Namespace 'root\ccm\invagt' -Class 'InventoryActionStatus' -ComputerName $c

            if ($HwInvRecord | Where-Object -FilterScript {$_.InventoryActionId -eq '{00000000-0000-0000-0000-000000000001}'})
            {
                $HwInvRecord | Where-Object -FilterScript {$_.InventoryActionId -eq '{00000000-0000-0000-0000-000000000001}'} | Remove-WmiObject
                $HwInvRecord = Get-WmiObject -Namespace 'root\ccm\invagt' -Class 'InventoryActionStatus' -ComputerName $c
            }

            if (!($HwInvRecord | Where-Object -FilterScript {$_.InventoryActionId -eq '{00000000-0000-0000-0000-000000000001}'}))
            {
                Write-Host "SUCCESS" -ForegroundColor Green
            }
            else
            {
                Write-Host "FAILED" -ForegroundColor Yellow
            }
        }
        else
        {
            Write-Host "Couldn't connect to " -NoNewline
            Write-Host $c -ForegroundColor Cyan
        }
    }
}