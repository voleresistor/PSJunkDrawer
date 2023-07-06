function Connect-PufferSearchAndDestroy {
    <#
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Exchange', 'Compliance')]
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

    # Check the state of winRM if not using ExchangeOnline REST commands
    if ($ConnectType -eq 'Compliance') {
        $winrmKeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client'
        $winrmValueName = 'AllowBasic'
        $winrmExpectedValue = 1
        $winrmValue = (Get-ItemProperty -Path $winrmKeyPath -Name $winrmValueName | select -ExpandProperty $winrmValueName)

        if ($winrmValue -ne $winrmExpectedValue) {
            try {
                Set-ItemProperty -Path $winrmKeyPath -Name $winrmValueName -Value $winrmExpectedValue -ErrorAction Stop
            }
            catch {
                Write-Error $_.Exception.Message
                $result = $False
            }
        }
    }

    # Verify we aren't connected and try to connect
    $CurrentState = Get-PSSession | Where-Object {
        $_.ConfigurationName -eq $ConfigName -and `
        $_.State -eq $TargetState -and `
        $_.ComputerName -eq $ComputerName
    }
    if (-Not $CurrentState) {
        Write-Verbose "${scriptName}: Not currently connected."
        Write-Verbose "${scriptName}: Attempting connection to $ConnectType."
        #Connect-ExchangeOnline -ConnectionUri $ConnectionUri -CommandName $ImportCmd
        $Identity = "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
        if ($ConnectType -eq 'Exchange') {
            try {
                Connect-ExchangeOnline -UserPrincipalName $Identity -Erroraction Stop
            }
            catch {
                Write-Error $_.Exception.Message
                $result = $False
            }
        }
        elseif ($ConnectType -eq 'Compliance') {
            try {
                Connect-IPPSSession -UserPrincipalName $Identity -Erroraction Stop
            }
            catch {
                Write-Error $_.Exception.Message
                $result = $False
            }
        }
    }
    else {
        Write-Verbose "${scriptName}: Nothing to do as we are already connected!"
    }

    return $result
}