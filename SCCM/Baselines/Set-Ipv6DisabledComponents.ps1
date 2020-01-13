function Set-Ipv6DisabledComponents
{
    param
    (
        [parameter(Mandatory=$true)]
        [ValidateSet('Prefer4','Disable6')]
        [string]$Setting,

        [parameter(DontShow)]
        [string]$KeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters',

        [parameter(DontShow)]
        [string]$ValueName = 'DisabledComponents'
    )

    $settingHash = @{'Prefer4'=32; 'Disable6'=255}
    $settingDec = $settingHash[$Setting]

    if (Get-ItemProperty -Name $ValueName -Path $KeyPath -ErrorAction SilentlyContinue)
    {
        #Get-ItemProperty -Name $ValueName -Path $KeyPath
        Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $settingDec -Force
    }
    else
    {
        #Write-Host "Adding property $KeyPath\DisabledComponent"
        New-ItemProperty -Path $KeyPath -Name $ValueName -Value $settingDec -PropertyType DWORD -Force
    }
}