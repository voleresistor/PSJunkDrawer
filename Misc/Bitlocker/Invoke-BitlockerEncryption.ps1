function Invoke-BitlockerEncryption {
    [CmdletBinding()]

    param (

    )

    $Tpm = Get-Tpm
    
    # Only continue if there's a TPM and it's ready.
    if ($($Tpm.TpmPresent) -eq 'True' -and $($Tpm.TpmReady) -eq 'True') {
        if ((Get-BitLockerVolume).VolumeStatus -eq 'FullyDecrypted') {
            Write-Verbose 'manage-bde -on c: -recoverypassword -skiphardwaretest'
            #$TargetVolume = Get-BitLockerVolume -MountPoint "C:"
            Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector -SkipHardwareTest
        }
        else {
            Write-Verbose 'Volume already encrypted.'
        }
    }
    else {
        Write-Verbose 'No TPM present or TPM not ready.'
    }
}

# Start encryption
Invoke-BitlockerEncryption -Verbose
Get-BLStatus -Verbose