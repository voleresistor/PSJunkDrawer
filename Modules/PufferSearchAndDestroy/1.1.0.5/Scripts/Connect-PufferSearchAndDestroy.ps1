function Connect-PufferSearchAndDestroy {
    <#
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Office', 'Nam04')]
        [string]$ConnectType,

        [Parameter(Mandatory=$False)]
        [string]$ImportCmd
    )

    # What's the status of this run?
    # Non-null states are considered errors
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # What do we need to connect to and what commands do we need to import?
    $ConfigName = 'Microsoft.Exchange'
    $TargetState = 'Opened'
    if ($ConnectType -eq 'Office') {
        $ComputerName = 'outlook.office365.com'
        $ConnectionUri = 'https://outlook.office365.com/powershell-liveid/'

        if (!($ImportCmd)) {
            $ImportCmd = @(
                'Get-HostedContentFilterPolicy',
                'Set-HostedContentFilterPolicy',
                'Get-TransportRule',
                'Set-TransportRule'
            )
        }
    }
    else {
        $ComputerName = 'nam04b.ps.compliance.protection.outlook.com'
        $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'

        if (!($ImportCmd)) {
            $ImportCmd = @(
                'New-ComplianceSearchAction',
                'New-ComplianceSearch',
                'Start-ComplianceSearch',
                'Get-ComplianceSearchAction',
                'Get-ComplianceSearch'
            )
        }
    }

    # Verify we aren't connected and try to connect
    $CurrentState = Get-PSSession | Where-Object {
        $_.ConfigurationName -eq $ConfigName -and `
        $_.State -eq $TargetState -and `
        $_.ComputerName -eq $ComputerName
    }
    if (-Not $CurrentState) {
        Write-Verbose "${scriptName}: Not currently connected so attempt to connect."
        #Connect-ExchangeOnline -ConnectionUri $ConnectionUri -CommandName $ImportCmd
        try {
            Connect-ExchangeOnline -ConnectionUri $ConnectionUri -Erroraction Stop
        }
        catch {
            Write-Error $_.Exception.Message
            $result = $False
        }
    }
    else {
        Write-Verbose "${scriptName}: Already connected, nothing to do!"
    }

    return $result
}