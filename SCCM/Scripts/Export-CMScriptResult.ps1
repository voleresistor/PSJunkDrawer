Function Export-CMScriptResults
{
<#
.Synopsis
   Export-CMScriptResults
.DESCRIPTION
   Export-CMScriptResults exports the return values from scripts that are executed
   through the ConfigMgr Run Script feature. 
.PARAMETER ScriptName
   The name of the Script as it is displayed within the ConfigMgr Console. 
.PARAMETER Site Server
    The computer name of the CofnigMgr site server

.PARAMETER SiteCode
    The site code of the ConfigMgr instance

.EXAMPLE
    Export-CMScriptResults -ScriptName Test -SiteCode P01 -SiteServer sccm1 -OutPutLocation c:\dev -Verbose

    The above command extracts the results from the Script named 'Test'

.NOTES
    v1.0, Alex Verboon, September 9. 2019

#>
    [CmdletBinding()]
    Param
    (
        # The name of the Script
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ScriptName,

        # ConfigMgr Site Code
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $SiteCode="P01",
        # ConfigMgr Site Server Computername
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $SiteServer="$ENV:COMPUTERNAME",
        
        # The name of the Script
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $OutPutLocation="C:\TEMP"
    )

    Begin
    {

        [string]$SiteServer = $SiteServer
        [string]$SiteCode = $SiteCode
        [string]$Namespace = "root\SMS\site_$SiteCode"

        $TimeStamp = $(get-date -f dd-MM-yyyy-HH-m-ss)
        $tmpoutputfile = "$ENV:Temp\$($ScriptName)_$TimeStamp.txt"
        Write-Verbose "ScriptName: $ScriptName"
        Write-Verbose "TempOutPutFile: $tmpoutputfile"

    }
    Process
    {
        $Script = Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -ClassName SMS_Scripts | Where-Object {$_.ScriptName -eq "$ScriptName"}
        If ([string]::IsNullOrEmpty($Script))
        {
            Write-warning "No Script found with the name $ScriptName in the ConfigMgr Script Repository"
            break
        }
        Else
        {
            Write-Verbose "Script $ScriptName found in ConfigMgr script library"
            $ExecTask = Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -ClassName SMS_ScriptsExecutionTask | Where-Object {$_.ScriptGuid -eq $Script.ScriptGuid} | Sort-Object ClientOperationId | Select-Object * -Last 1
            If ([string]::IsNullOrEmpty($ExecTask))
            {
                Write-Warning "No Script Tasks found for Script $ScriptName"
                break
            }        
            Else
            {
                Write-Verbose "Script Task found for script $ScriptName"
                $status = Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -ClassName SMS_ScriptsExecutionStatus |Where-Object {$_.TaskID -eq $ExecTask.TaskID}
                $Summary = Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -ClassName SMS_ScriptsExecutionSummary | Where-Object {$_.TaskID -eq $ExecTask.TaskID}
                $summaryOutputTargets = @($Summary | where-object {$_.GroupType -eq 1})

                If ($summaryOutputTargets.count -gt 0)
                {
                    Write-Verbose "Processing Script results for script $ScriptName"
                    ForEach ($result in $summaryOutputTargets)
                    {
                        $result.ScriptOutput | Out-File -FilePath "$tmpoutputfile" -Append -Force
    
                    }

                    try {
                        $OutPutData = Get-content -Path $tmpoutputfile | ConvertFrom-Json -ErrorAction Stop
                        $validJson = $true;
                    } catch {
                        $validJson = $false;
                        $OutPutData = @(Get-content -Path $tmpoutputfile)
                    }
                }
                Else
                {
                    Write-Warning "No Script Deployment results found for Script $ScriptName" 
                    break
                }
            }
        } 
    }
    End
    {
        # Do we want the output written to file ?
        If($PSBoundParameters.ContainsKey("OutPutLocation"))
        {
            $TimeStamp = $(get-date -f dd-MM-yyyy-HH-m-ss)
            $OutPutfile = "$OutPutLocation\$($ScriptName)_$TimeStamp.txt"
            Write-Verbose "OutPutFile: $OutPutfile"
            If ($validJson -eq $false)
            {
                $OutPutData | Out-File -FilePath $OutPutfile -NoClobber
            }
            Elseif ($validJson -eq $true)
            {
                $OutPutData | Export-Csv -Path $OutPutfile -NoClobber -NoTypeInformation
            }
        }
        $OutPutData
    }
}