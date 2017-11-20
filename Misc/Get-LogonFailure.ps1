# requires Admin privileges!
Param ($RemoteComp = $env:ComputerName)
function Get-LogonFailure
{
      param($ComputerName = $env:ComputerName)

      try
      {
             Get-EventLog -LogName security -EntryType FailureAudit -InstanceId 4625 -ErrorAction Stop @PSBoundParameters |
                  ForEach-Object {
                          $domain, $user = $_.ReplacementStrings[5,6]
                          $time = $_.TimeGenerated
                          Write-Host "Logon Failure: $domain\$user at $time" -ForegroundColor Red
                   }
      }

      catch
      {
            if ($_.CategoryInfo.Category -eq 'ObjectNotFound')
            {
                  Write-Host "No logon failures found." -ForegroundColor Green
            }
            else
            {
                  Write-Warning "Error occured: $_"
            }
      }
 }
 
 Get-LogonFailure -ComputerName $RemoteComp 