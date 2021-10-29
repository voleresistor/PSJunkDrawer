function Add-ProductKey {
    $changePKPath = "C:\Windows\System32\changePK.exe"
    try {
        Start-Process -FilePath $changePKPath -ArgumentList "/ProductKey $ProductKey"
        Write-Host "The product key has been added."
    } catch {
        Write-Host "An error occured when attempting to add the Product Key."
    }
}
 
function Get-ProductKey {
    try {
        $ProductKey = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey
        Write-Host "The Product Key is: $ProductKey"
        Add-ProductKey
    } catch {
        Write-Host "An error occured when attempting to access the Product Key."
    }
}
 
function Get-ActivationStatus {
    $ActivationStatus = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object PartialProductKey).LicenseStatus
    try {
        if ($ActivationStatus = 1) {
            Write-Host "Windows is activated. [Activation Status = $ActivationStatus]"
        } elseif ($ActivationStatus = 0) {
            Write-Host "Windows is NOT activated. [Activation Status = $ActivationStatus]"
            Get-ProductKey
        } 
    } catch {
        Write-Host "An error occurred when attempting to access the Windows activation status."
    }
}