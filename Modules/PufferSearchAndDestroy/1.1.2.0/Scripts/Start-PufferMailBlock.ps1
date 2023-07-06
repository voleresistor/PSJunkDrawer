function Start-PufferMailBlock {
    <#
    .SYNOPSIS
    Update Puffer mail rules to block delivery of matching emails in the future.
    .DESCRIPTION
    Update Puffer mail rules to block delivery of matching emails in the future.
    .EXAMPLE
    Start-PufferMailBlock -Sender ‘info@spammer.com’
    Add a rule to the default anti-spam rule blocking delivery of future emails from info@spammer.com.
    .EXAMPLE
    Start-PufferMailBlock -Domain ‘spammer.com’
    Add a rule to the default anti-spam rule blocking delivery of future emails from any address at the spammer.com domain.
    .PARAMETER Body
    Block emails whose body matches this text.
    .PARAMETER Domain
    Block emails that are apparently from this domain.
    .PARAMETER Header
    Block emails whose header matches this header string.
    .PARAMETER Sender
    Block email whose sender matches this address.
    .PARAMETER Subject
    Block emails whose subject matches this text.
    .OUTPUTS
    Feedback from Compliance backend.
    .NOTES
    Andrew Ogden @ Puffer-Sweiven
    Matthew Silcox @ Catapult Systems
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Body')]
        [string]$Body,

        [Parameter(Mandatory=$true, ParameterSetName='Sender')]
        [string]$Sender,

        [Parameter(Mandatory=$true, ParameterSetName='Subject')]
        [string]$Subject,

        [Parameter(Mandatory=$true, ParameterSetName='Header')]
        [string]$Header,

        [Parameter(Mandatory=$true, ParameterSetName='Domain')]
        [string]$Domain
    )

    # What's the status of this run?
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # Make sure we're connected to ExchangeOnline
    Write-Verbose "${scriptName}: Verify connection to ExchangeOnline..."
    $connectResult = Connect-PufferSearchAndDestroy -ConnectType 'Office'
    if ($connectResult -ne $null) {
        Write-Warning 'There was an issue connecting to ExchangeOnline.'
        $result -eq $false
    }

    if ($result -eq $null) {
        # Sender
        if ($Sender) {
            Write-Verbose "${scriptName}: Adding $Sender to the Default Spam Filter Policy..."
            $rulecontents = @()
            $rulecontents = Get-HostedContentFilterPolicy -Identity "Default" | select -ExpandProperty BlockedSenders
            $rulecontents += $Sender
            Set-HostedContentFilterPolicy -Identity "Default" -BlockedSenders $rulecontents
        }

        # Domain
        if ($Domain) {
            Write-Verbose "${scriptName}: Adding $Domain to the Default Spam Filter Policy..."
            $rulecontents = @()
            $rulecontents = Get-HostedContentFilterPolicy -Identity "Default" | select -ExpandProperty BlockedSenderDomains
            $rulecontents += $Domain
            Set-HostedContentFilterPolicy -Identity "Default" -BlockedSenderDomains $rulecontents
        }

        # Body
        if ($Body) {
            Write-Verbose "${scriptName}: Adding $Body to the '[Phish Block] Body' ETR..."
            $rulecontents = @()
            $rulecontents = Get-TransportRule -Identity "[Phish Block] Body" | select -ExpandProperty SubjectOrBodyContainsWords
            $rulecontents += $body
            Set-TransportRule -Identity "[Phish Block] Body" -BlockedSenders $rulecontents
        }

        # Subject
        if ($Subject) {
            Write-Verbose "${scriptName}: Adding $Subject to the '[Phish Block] Subject' ETR..."
            $rulecontents = @()
            $rulecontents = Get-TransportRule -Identity "[Phish Block] Subject" | select -ExpandProperty SubjectOrBodyContainsWords
            $rulecontents += $Subject
            Set-TransportRule -Identity "[Phish Block] Subject" -BlockedSenders $rulecontents
        }

        # Header
        if ($Header) {
            Write-Verbose "${scriptName}: Adding $Header to the '[Phish Block] Header' ETR..."
            $rulecontents = @()
            $rulecontents = Get-TransportRule -Identity "[Phish Block] Header" | select -ExpandProperty SubjectOrBodyContainsWords
            $rulecontents += $Header
            Set-TransportRule -Identity "[Phish Block] Header" -BlockedSenders $rulecontents
        }
    }

    # Disconnect
    Write-Verbose "${scriptName}: Disconnect from ExchangeOnline..."
    $disconnectResult = Disconnect-PufferSearchAndDestroy -ConnectType 'Office'
    if ($disconnectResult -ne $null) {
        Write-Warning "Remote sessions not fully disconnected."
    }

    return $result
}
