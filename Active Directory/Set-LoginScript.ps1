
function Set-LoginScript {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,Position=1,ValueFromPipeLine=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser[]]$User,

        [Parameter(Mandatory=$false, Position=2,ParameterSetName='Replace')]
        [string]$NewScriptPath,

        [Parameter(Mandatory=$false, ParameterSetName='Remove')]
        [switch]$Remove
    )

    foreach ($u in $User) {
        if ([string]::IsNullOrEmpty($u.ScriptPath)){
            $CurrentPath = 'Null'
        }
        else {
            $CurrentPath = $($u.ScriptPath)
        }

        Write-Host "$($u.Name) - $CurrentPath"

        try {
            if ($NewScriptPath) {
                Set-ADUser -ScriptPath $NewScriptPath -Identity $u
            }
            elseif ($Remove) {
                Set-ADUser -identity $u -Remove @{ScriptPath="$CurrentPath"}
            }
        }
        catch {
            Write-Host "`tFAILED" -ForegroundColor Red
            continue
        }
        Write-Host "`tSUCCESS" -ForegroundColor Green
    }
}