param (
    [string]$computer
)

$remotereg = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft Antimalware\Signature Updates' -Name ASSignatureVersion | Select ASSignatureVersion)

Invoke-Command -ComputerName $computer -ScriptBlock $remotereg