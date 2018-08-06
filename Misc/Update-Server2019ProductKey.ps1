param
(
    [Parameter(Mandatory=$true)]
    [string]$ProductKey
)

# Attempt to install the product key
$ipk = Start-Process -FilePath "$env:windir\System32\cscript.exe" -ArgumentList "$env:windir\system32\slmgr.vbs /ipk $ProductKey" -PassThru
Wait-Process -InputObject $ipk

# Check status of installation
if ($ipk.ExitCode -ne 0)
{
    Write-Output "$_ exited with status code $($ipk.ExitCode)"
    exit
}

# Attempt to activate the product key
$ato = Start-Process -FilePath "$env:windir\System32\cscript.exe" -ArgumentList "$env:windir\system32\slmgr.vbs /ato"
Wait-Process -InputObject $ato
Write-Output "$_ exited with status code $($ato.ExitCode)"