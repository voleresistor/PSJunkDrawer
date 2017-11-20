$host.Runspace.ThreadOptions = "ReuseThread"
Add-Type -AssemblyName System.Printing

$permissions = [System.Printing.PrintSystemDesiredAccess]::AdministrateServer
$queueperms = [System.Printing.PrintSystemDesiredAccess]::AdministratePrinter
$server = new-object System.Printing.PrintServer -argumentList $permissions
$queues = $server.GetPrintQueues(@([System.Printing.EnumeratedPrintQueueTypes]::Shared))

$queues