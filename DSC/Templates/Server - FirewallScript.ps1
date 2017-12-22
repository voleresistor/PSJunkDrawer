Configuration FirewallScript
{
    param
    (
        [string]$DisplayGroup,

        [ValidateSet('True', 'False')]
        [string]$Enable
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Script SetFirewall
    {
        #Must return a hashtable with Result = <something>
        GetScript = {
            Return @{
                Result = [string]$(if ((Get-NetFirewallRule -DisplayGroup $DisplayGroup).Enabled -like '*False*'){'False'}else{'True'})
            }
        }

        TestScript = {
            if ((Get-NetFirewallRule -DisplayGroup 'DFS Replication').Enabled -like '*False*')
            {
                Write-Verbose "One of the rules in the firewall group $DisplayGroup is disabled."
                return $false
            }
            else
            {
                Write-Verbose "All of the rules in the firewall group $DisplayGroup are enabled."
                return $true
            }
        }

        SetScript = {
            Write-Verbose "Enabling all rules in firewall rule group: $DisplayGroup"
            foreach ($Rule in (Get-NetFirewallRule -DisplayGroup $DisplayGroup))
            {
                Set-NetFirewallRule -Name $($Rule.Name) -Enabled $Enabled | Out-Null
            }
        }
    }
}

$ConfigName = 'FirewallScript'
$ConfigRoot = 'C:\DSCConfig'
# Create and cd to a dedicated config folder
if (!(Test-Path -Path $ConfigRoot))
{
    New-Item -Path $ConfigRoot -ItemType Directory -Force
}

Set-Location -Path $ConfigRoot
FirewallScript -DisplayGroup 'DFS Replication' -Enabled 'True'
Rename-Item -Path "$ConfigRoot\$ConfigName\localhost.mof" -NewName "$ConfigName.mof"
New-DscChecksum -Path "$ConfigRoot\$ConfigName" #Generate a checksum

#Start-DscConfiguration -Path .\FirewallScriptResource -Wait -Verbose

#Get-DscConfiguration