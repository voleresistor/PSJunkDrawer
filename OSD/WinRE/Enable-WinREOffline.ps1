$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$osdisk = $tsenv.Value('OSDisk')
$osPartString = "device                  partition=$osdisk"

$osGUID = ((((& $env:windir\system32\bcdedit.exe -enum -v | Select-String $osPartString -Context 1,0) -split (" "))[16]) -split ("`r`n"))[0]

# Regex for GUID
#"^\{[a-z 0-9]{8}(\-[0-9 a-z]{4}){3}\-[0-9 a-z]{12}\}$"