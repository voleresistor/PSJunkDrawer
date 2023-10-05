function Disconnect-PufferSearchAndDestroy {
    <#
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('Office', 'Compliance', 'All')]
        [string]$ConnectType = 'All'
    )

    # What's the status of this run?
    # Non-null states are considered errors
    $result = $null

    # What are we trying to disconnect from?
    $ConfigName = 'Microsoft.Exchange'
    $TargetState = 'Opened'
    if ($ConnectType -eq 'Office') {
        $ComputerName = 'outlook.office365.com'
    }
    elseif ($ConnectType -eq 'Compliance') {
        $ComputerName = 'nam04b.ps.compliance.protection.outlook.com'
    }

    # If we said all just grab everything
    if ($ConnectType -eq 'All') {
        $CurrentState = Get-PSSession | Where-Object {
            $_.ConfigurationName -eq $ConfigName -and `
            $_.State -eq $TargetState
        }
    }
    # Else just snatch up the specific connections
    else {
        $CurrentState = Get-PSSession | Where-Object {
            $_.ConfigurationName -eq $ConfigName -and `
            $_.State -eq $TargetState -and `
            $_.ComputerName -eq $ComputerName
        }
    }

    # KILL EM
    if ($CurrentState) {
        Remove-PSSession -Id $CurrentState.Id -Confirm:$false
    }

    return $result
}