function Set-ServiceRecovery {
    # https://evotec.xyz/set-service-recovery-options-powershell/
    [alias('Set-Recovery')]
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,

        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [ValidateSet('Restart')]
        [string] $FirstAction = "Restart",

        [int] $FirstTime =  30000, # in miliseconds

        [ValidateSet('Restart')]
        [string] $SecondAction = "Restart",

        [int] $SecondTime =  30000, # in miliseconds

        [ValidateSet('Restart')]
        [string] $LastAction = "Restart",

        [int] $LastTime = 30000, # in miliseconds

        [int] $ResetTime = 4000 # in seconds
    )

    $serverPath = "\\" + $ComputerName
    $services = Get-CimInstance -ClassName 'Win32_Service' -ComputerName $ComputerName | Where-Object {$_.DisplayName -imatch $DisplayName}
    $action = $FirstAction+"/"+$FirstTime+"/"+$SecondAction+"/"+$SecondTime+"/"+$LastAction+"/"+$LastTime
    foreach ($service in $services){
        # https://technet.microsoft.com/en-us/library/cc742019.aspx
        $output = sc.exe $serverPath failure $($service.Name) actions= $action reset= $ResetTime
    }
}