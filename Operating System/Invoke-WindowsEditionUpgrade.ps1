function Update-EditionKey {
    param (
        [string]$GVLK = 'NPPR9-FWDCX-D2C8J-H872K-2YT43',

        [string]$TargetEdition = 'Enterprise',

        [string]$TargetPartialKey = $($GVLK -split('-'))[-1]
    )
    #Gather current edition and prtial key
    $CurrentEdition = (Get-CimInstance -ClassName win32_OperatingSystem).Caption
    $CurrentPartialKey = ((cscript $env:windir\system32\slmgr.vbs /dlv | select-String -Pattern "Partial Product Key") -split(": "))[1]

    # Check for and update key if necessary
    if ($CurrentEdition -like "*$TargetEdition*" -or $CurrentPartialKey -eq $TargetPartialKey){
        Write-OutPut "Already at $TargetEdition with partial key $TargetPartialKey"
        return
    } else {
        # Try/catch to handle possible errors
        try {
            Start-Process -FilePath "$env:SYSTEMROOT\System32\cscript.exe" -ArgumentList "${env:\SYSTEMROOT}\system32\slmgr.vbs /ipk $GVLK" -NoNewWindow -Wait
        }
        catch {
            Write-Output $_.Message.Exception
        }
    }

    # Check that partial key successfully changed, assuming we passed the catch{} statement above
    $NewPartialKey = ((cscript $env:windir\system32\slmgr.vbs /dlv | select-String -Pattern "Partial Product Key") -split(": "))[1]
    if ($NewPartialKey -ne $TargetPartialKey) {
        Write-Output "FAIL: Partial key not updated: $NewPartialKey"
        return
    }
    else {
        Write-Output "SUCCESS: Partial Key updated: $NewPartialKey"
        return
    }

    Write-Output "Something funky happened"
    return
}