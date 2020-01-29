function Invoke-CMClientAction
{
    <#
    .SYNOPSIS
    Remotely schedule SCCM client actions.
    
    .DESCRIPTION
    Request that the SCCM scheduler on remote machines perform actions.
    
    .PARAMETER ComputerName
    Target computer.
    
    .PARAMETER ClientAction
    Action to perform.
    
    .EXAMPLE
    Invoke-CMClientAction -ComputerName pc001 -ClientAction MachinePolEvalCycle
    
    .NOTES
    General notes
    #>

    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true,Position=1)]
        [ValidateSet('ResetPolicy','RequestMachinePolicy','EvaluateMachinePolicy','RepairClient','GetAssignedSite','AppEval','UpdateScan','UpdatesDeployment')]
        [string]$ClientAction
    )

    begin
    {
        # Set up a PSRemoting session, throw and error and freak the fuck out if it fails
        try
        {
            $remoteSession = New-PSSession -ComputerName $ComputerName
        }
        catch
        {
            throw $_.Exception.Message
        }
    }

    process
    {
        # Scriptblock is slightly different if action is AppEval since there's no method explicitly for that action
        if ($ClientAction -eq 'AppEval')
        {
            $remoteScriptBlock = { Invoke-CimMethod -ClassName 'SMS_Client' -NameSpace 'root\ccm' -MethodName TriggerSchedule -Arguments @{ sScheduleId = '{00000000-0000-0000-0000-000000000121}' } }
        }
        elseif ($ClientAction -eq 'UpdateScan')
        {
            $remoteScriptBlock = { Invoke-CimMethod -ClassName 'SMS_Client' -NameSpace 'root\ccm' -MethodName TriggerSchedule -Arguments @{ sScheduleId = '{00000000-0000-0000-0000-000000000113}' } }
        }
        elseif ($ClientAction -eq 'UpdatesDeployment')
        {
            $remoteScriptBlock = { Invoke-CimMethod -ClassName 'SMS_Client' -NameSpace 'root\ccm' -MethodName TriggerSchedule -Arguments @{ sScheduleId = '{00000000-0000-0000-0000-000000000108}' } }
        }
        else
        {
            $remoteScriptBlock = { Invoke-CimMethod -ClassName 'SMS_Client' -NameSpace 'root\ccm' -MethodName $($Using:ClientAction) }
        }

        # Use the remote session to run the requested SMS_Client class method
        Invoke-Command -Session $remoteSession -ScriptBlock $remoteScriptBlock
    }

    end
    {
        # Kill the open session
        Remove-PSSession -Session $remoteSession
    }
}