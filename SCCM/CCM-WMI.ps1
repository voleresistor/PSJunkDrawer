param
(
    [Parameter(Mandatory=$true, Position=1)]
    [string[]]$ComputerName,

    [Parameter(Mandatory=$false)]
    [switch]$Repair,

    [Parameter(Mandatory=$false)]
    [switch]$Reset,

    [Parameter(Mandatory=$false)]
    [switch]$Request,

    [Parameter(Mandatory=$false)]
    [switch]$Eval,

    [Parameter(Mandatory=$false)]
    [switch]$AppEval
)

<#
    I don't know why, but it looks like I was trying to
    dynamically generate an array of computernames instead of just
    allowing PowerShell to handle it automatically.

# Create list of computers based on user inputs
if ($computerList -and $computerName) {
    $computers = @(Get-Content $computerList)
    $computers += $computerName
} elseif ($computerList -and (-not($computerName))) {
    $computers = @(Get-Content $computerList)
} elseif ($computerName -and (-not($computerList))){
    $computers = @($computerName)
} elseif (-not($computerList -and (-not($computerName)))){
    $computers = @($env:COMPUTERNAME)
}#>

# Use WMI to invoke various CM client functions remotely via WMI
forEach ($c in $ComputerName){
    $smsClient = [wmiclass]"\\$c\root\ccm:SMS_Client"
    
    if ($Request){
        $smsClient.RequestMachinePolicy()
    }
    if ($Repair){
        $smsClient.RepairClient()
    }
    if ($Reset){
        $smsClient.ResetPolicy()
    }
    if ($Eval){
        $smsClient.EvaluateMachinePolicy()
    }
    if ($AppEval){
        $smsClient.TriggerSchedule("{00000000-0000-0000-0000-000000000121}")
    }
}