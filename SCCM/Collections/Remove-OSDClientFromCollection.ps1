$computer = $env:COMPUTERNAME 
$remotesession = New-PSSession -ComputerName housccm03.dxpe.com -ConfigurationName Microsoft.PowerShell32 
Invoke-Command -Session $remotesession -ScriptBlock { 
    param($computer) 
    Import-module 'D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' 
        Set-Location HOU: 
        Remove-CMDeviceCollectionDirectMembershipRule -CollectionName "OS Build Software Updates" -ResourceID (Get-CMDevice -Name $computer).ResourceID 
} -Args $computer 
Remove-PSSession $remotesession