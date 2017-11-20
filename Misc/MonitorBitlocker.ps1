Function Get-BLStatus ($ComputerName)
{
    try
    {
        $BLMonSession = New-PSSession -ComputerName $ComputerName
        
        do
        {
            $Volume = (Invoke-Command -Session $BLMonSession -ScriptBlock {Get-BitLockerVolume -MountPoint $env:SystemDrive})
            Write-Progress -Activity "Encrypting volume $($Volume.MountPoint) on $ComputerName" -Status "Encryption Progress - $($Volume.EncryptionPercentage)%" -PercentComplete $Volume.EncryptionPercentage
            Start-Sleep -Seconds 1
        }
        until ($Volume.VolumeStatus -eq 'FullyEncrypted')
    }
    finally
    {
        Remove-PSSession -Id $($a.Id)
    }
}