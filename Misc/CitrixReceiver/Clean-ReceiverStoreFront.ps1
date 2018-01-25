#Get OS architecture from WMI
$OSArch = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture

Write-Host "$OSArch architecture detected"
if ($OSArch -eq '64-bit')
{
    $selfservice = "C:\Program Files (x86)\Citrix\ICA Client\selfservicePlugin\selfservice.exe"
}
else #Assuming 32-bit if not 64-bit
{
    $selfservice = "C:\Program Files\Citrix\ICA Client\selfservicePlugin\selfservice.exe"
}

Start-Process -FilePath $selfservice -ArgumentList '-init -deleteproviderbyname HOSTED' -Wait -NoNewWindow
Start-Process -FilePath $selfservice -ArgumentList '-init -deleteproviderbyname HOUCTXSF02' -Wait -NoNewWindow
Start-Process -FilePath $selfservice -ArgumentList '-rmprograms' -Wait -NoNewWindow