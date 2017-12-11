function Invoke-SccmClientAction
{
    <#
    .SYNOPSIS
    Remotely begin SCCM client actions.
    
    .DESCRIPTION
    Request that the SCCM scheduler on remote machines perform the requested actions.
    
    .PARAMETER ComputerName
    Target computer.
    
    .PARAMETER ClientAction
    Action to perform.
    
    .EXAMPLE
    Invoke-SccmClientAction -ComputerName pc001 -ClientAction MachinePolEvalCycle

    Perform machine policy retrieval and evaluation cycle.
    
    .NOTES
    General notes
    #>
    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string]$ComputerName = 'localhost',

        [Parameter(Mandatory=$false)]
        [ValidateSet('AppDeployCycle',
                    'DDRCycle',
                    'FileCollectionCycle',
                    'HardwareInventoryCycle',
                    'MachinePolEvalCycle',
                    'SoftwareInvCycle',
                    'SoftwareMeteringReport',
                    'SoftwareUpdDepCycle',
                    'SoftwareUpdScanCycle',
                    'StateMessageRefresh',
                    'UserPolEvalCycle',
                    'WindowsInstallerSourceUpdate')]
        [string]$ClientAction
    )

    $SchduleList = @{
        'AppDeployCycle' = '{00000000-0000-0000-0000-000000000121}';
        'DDRCycle' = '{00000000-0000-0000-0000-000000000003}';
        'FileCollectionCycle' = '{00000000-0000-0000-0000-000000000104}';
        'HardwareInventoryCycle' = '{00000000-0000-0000-0000-000000000101}';
        'MachinePolEvalCycle' = '{00000000-0000-0000-0000-000000000022}';
        'SoftwareInvCycle' = '{00000000-0000-0000-0000-000000000102}';
        'SoftwareMeteringReport' = '{00000000-0000-0000-0000-000000000106}';
        'SoftwareUpdDepCycle' = '{00000000-0000-0000-0000-000000000108}';
        'SoftwareUpdScanCycle' = '{00000000-0000-0000-0000-000000000113}';
        'StateMessageRefresh' = '{00000000-0000-0000-0000-000000000111}';
        'UserPolEvalCycle' = '{00000000-0000-0000-0000-000000000027}';
        'WindowsInstallerSourceUpdate' = '{00000000-0000-0000-0000-000000000107}'
    }
    
    $SchedId = $($SchduleList[$ClientAction])

    if ($ClientAction -eq 'MachinePolEvalCycle')
    {
        $SubRes = Invoke-WmiMethod -ComputerName $ComputerName -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000021}'
        if ($SubRes.ReturnValue)
        {
            return "There was an error retrieving machine policy."
        }
    }

    if ($ClientAction -eq 'UserPolEvalCycle')
    {
        $SubRes = Invoke-WmiMethod -ComputerName $ComputerName -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000026}'
        if ($SubRes.ReturnValue)
        {
            return "There was an error retrieving user policy."
        }
    }

    $Result = Invoke-WmiMethod -ComputerName $ComputerName -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule $SchedId
    if (!($Result.ReturnValue))
    {
        return "$ClientAction completed successfully"
    }
    else
    {
        return "Error: $($Result.ReturnValue)"
    }
}