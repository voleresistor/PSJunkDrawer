param(
    [Parameter(Mandatory=$true)]
    [string]$RbId,

    [Parameter(Mandatory=$false)]
    [string]$LogLocation = "C:\Temp\OrchJobLogs",

    [Parameter(Mandatory=$true)]
    [string]$LogName,

    [Parameter(Mandatory=$false)]
    [string]$RbPath,

    [Parameter(Mandatory=$false)]
    [hashtable]$RbParams = @{} #ex @{"ParamGUID1"="Value";"ParamGUID2"="OtherValue"}
)

begin{
    # Import Orchestrator module
    $ModulePath = '\\dxpe.com\dfsa\scripts\Orchestrator\OrchestratorServiceModule.psm1'
    Import-Module $ModulePath
}

process{
    # Gather information required to kick off runbook
    $RbServerName = 'houorch01.dxpe.com'
    $ServiceUrl = Get-OrchestratorServiceUrl -Server $RbServerName
    $Runbook = Get-OrchestratorRunbook -ServiceUrl $ServiceUrl -RunbookId $RbId

    if ($Runbook -ne $null){
        if ($RbParams -eq $null){
            $job = Start-OrchestratorRunbook -Runbook $Runbook
        } else {
            $job = Start-OrchestratorRunbook -Runbook $Runbook -Parameters $RbParams
        }

        if ($job -ne $null){
            Add-Content -Value ("$(Get-Date)" + " - JobId = " + "$($job.id)") -Path "$LogLocation\$LogName.log"
        }else{
            Add-Content -Value ("$(Get-Date)" + " - No job started") -Path "$LogLocation\$LogName.log"
        }
    }
}

end{
    # remove modules
    Remove-Module OrchestratorServiceModule
}