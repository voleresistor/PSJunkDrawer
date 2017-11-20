param(
    [string]$Computer
)

#$remoteCommand = "get-process spoolsv | stop-process -force; while ((get-wmiobject -class win32_printer -erroraction silentlycontinue) -eq $null) { write-host "Waiting..."; start-sleep -seconds 10}; write-host "Done! Getting list of printers..."; get-wmiobject -class win32_printer"

Invoke-Command -ComputerName $Computer -ScriptBlock { get-process spoolsv | stop-process -force; while ((get-wmiobject -class win32_printer -erroraction silentlycontinue) -eq $null) { write-host "Waiting..."; start-sleep -seconds 10}; write-host "Done! Getting list of printers..."; get-wmiobject -class win32_printer }