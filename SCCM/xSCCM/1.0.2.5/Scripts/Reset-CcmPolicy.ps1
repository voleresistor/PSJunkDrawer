#region Reset-CcmPolicy
function Reset-CcmPolicy
{
    <#
        .SYNOPSIS
            Reset CM policies.
        .DESCRIPTION
            Instruct CCM to replace all local policies with freshly downloaded copies from the management point.
        .PARAMETER  ComputerName
            Target computer to reset.
        .PARAMETER  Purge
            Purge old policies before downloading new ones.
        .EXAMPLE
            Reset-CcmPolicy -ComputerName test-computer-01 -Purge $true
            Example 1
        .Notes
            Author : Andrew Ogden
            Email  : andrew.ogden@puffer.com
            Date   : 05/11/21
            Edited from this source:
                https://techibee.com/powershell/reset-and-purge-existing-policies-in-sccm-using-powershell/2093
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string[]]$ComputerName = $env:ComputerName,

        [Parameter(Mandatory=$false, Position=2)]
        [switch]$Purge = $false
    )

    $NameSpace = 'root\ccm'
    $ClassName = 'SMS_Client'
    $ResetMethod = 'ResetPolicy'
    $RequestMethod = 'RequestMachinePolicy'
    $EvalMethod = 'EvaluateMachinePolicy'

    # This var MUST be a UInt32 for the method to accept it
    [uint32]$Gflag = 0
    if($Purge)
    {
        $Gflag = 1
    }

    foreach($Computer in $ComputerName)
    {
        try
        {
            $CimSession = New-CimSession -ComputerName $computer
            Invoke-CimMethod -ClassName $ClassName -Arguments @{'uFlags' = $Gflag} -MethodName $ResetMethod -Namespace $NameSpace -CimSession $CimSession
            Start-Sleep -Seconds 3
            Invoke-CimMethod -ClassName $ClassName -Arguments @{'uFlags' = $Gflag} -MethodName $RequestMethod -Namespace $NameSpace -CimSession $CimSession
            Start-Sleep -Seconds 3
            Invoke-CimMethod -ClassName $ClassName -MethodName $EvalMethod -Namespace $NameSpace -CimSession $CimSession
            Remove-CimSession -CimSession $CimSession
        }
        catch
        {
            Write-Warning "Unable to complete reset on $computer"
            continue
        }
        
        Write-Host "Policy reset completed on $computer"
    }
}
<#
    Examples

#>
#endregion