$OldDrivers = Get-WmiObject -Class Win32_PNPSignedDriver | Where-Object -FilterScript {($_.DeviceClass -eq 'DISPLAY') -and ($_.DeviceName -ne 'LogMeIn Mirror Driver') -and ($_.DriverProviderName -ne '')}

foreach ($Driver in $OldDrivers)
{
    Start-Process -FilePath "$env:systemroot\system32\pnputil.exe" -ArgumentList "-f -d $($Driver.InfName)" -NoNewWindow -PassThru -Wait -RedirectStandardOutput C:\temp\Remove_Drivers.log
}