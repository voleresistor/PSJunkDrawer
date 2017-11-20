param(
    [string]$InputCsv,
    [string]$OutputCsv = "c:\temp\ModelOutput.csv"
)

$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

$printers = Import-Csv -Path $InputCsv

Add-Content -Value "Name,IP Address,Model" -Path $OutputCsv
foreach ($ip in $printers){
    # Create the SNMP ComObject and open a connection to the printer
    $snmp = New-Object -ComObject olePrn.OleSNMP
    $snmp.Open("$($ip.IpAddress)", "public", 2, 3000)

    # Query the OID that contains Model information and extract only the model name data
    $model = $snmp.GetTree(".1.3.6.1.2.1.43.5.1.1.16") | Select-Object -Last 1
    Add-Content -Value "$($ip.Name),$($ip.IpAddress),$model" -Path $OutputCsv

    #Reset the variables to default values
    $snmp=$null
    $model="No Information"
}

$ErrorActionPreference = $oldEAP