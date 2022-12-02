function Start-PufferSearchAndDestroy {
    <#
    .SYNOPSIS
    Begin a search, purge, and optionally, block action.
    .DESCRIPTION
    Begin a search, purge, and block action. This meta-cmdlet wraps up the functionality of all the other module cmdlets into a single command to sequence them all.
    .EXAMPLE
    Start-PufferSearchAndDestroy -From ‘info@spammer.com’
    Search for and purge any email sent by info@spammer.com in the last 24 hours.
    .EXAMPLE
    Start-PufferSearchAndDestroy -From ‘info@spammer.com’ -BlockSender
    Search for and purge any email sent by info@spammer.com in the last 24 hours and block that sender.
    .EXAMPLE
    Start-PufferSearchAndDestroy --Domain ‘spammer.com’ -BlockDomain
    Search for and purge any email sent from spammer.com in the last 24 hours and block all future emails from that domain.
    .EXAMPLE
    Start-PufferSearchAndDestroy -From ‘info@spammer.com’ -BlockSender -BlockDomain
    Search for and purge any email sent from info@spammer.com in the last 24 hours, block that sender, and block the domain.
    .PARAMETER BlockBody
    Add and entry to the Body ETR to block future emails with the matching text in the body.
    .PARAMETER BlockDomain
    Add an entry to the default anti-spam rule to block the sender domain.
    .PARAMETER BlockHeader
    Add an entry to the Header ETR to block future emails with matching headers.
    .PARAMETER BlockSender
    Add an entry to the default anti-spam rule to block the sender.
    .PARAMETER BlockSubject
    Add an entry to the Subject ETR to block future emails with the matching text in the subject line.
    .PARAMETER Body
    All or part of the body of the email.
    .PARAMETER Domain
    The domain of the spammer or malicious sender.
    .PARAMETER EndDate
    The latest date up to which to search for emails.
    Default: The current day.
    .PARAMETER From
    The email address of the spammer or malicious sender.
    .PARAMETER Header
    All or part of the header.
    .PARAMETER StartDate
    The earliest date from which to search for emails.
    Default: The previous day.
    .PARAMETER Subject
    All or part of the subject line of the email.
    .PARAMETER To
    Any recipient.
    .NOTES
    Andrew Ogden @ Puffer-Sweiven
    Matthew Silcox @ Catapult Systems
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='From',Position=1)]
        [string]$From,

        [Parameter(Mandatory=$true,ParameterSetName='Domain',Position=1)]
        [string]$Domain,

        [Parameter(Mandatory=$false)]
        [string]$To,

        [Parameter(Mandatory=$false)]
        [String]$Subject,

        [Parameter(Mandatory=$false)]
        [String]$Body,

        [Parameter(Mandatory=$false)]
        [String]$Header,

        [Parameter(Mandatory=$false)]
        [DateTime]$StartDate = $((Get-Date).AddDays(-1)),

        [Parameter(Mandatory=$false)]
        [DateTime]$EndDate = $(Get-Date),

        [Parameter(Mandatory=$false,ParameterSetName='From')]
        [switch]$BlockSender,

        [Parameter(Mandatory=$false)]
        [switch]$BlockDomain,

        [Parameter(Mandatory=$false)]
        [switch]$BlockSubject,

        [Parameter(Mandatory=$false)]
        [switch]$BlockBody,

        [Parameter(Mandatory=$false)]
        [switch]$BlockHeader,

        [Parameter(Mandatory=$false)]
        [switch]$Disconnect = $True
    )

    # What's the status of this run?
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # Make sure we're connected to ExchangeOnline
    Write-Verbose "${scriptName}: Verify connection to ExchangeOnline..."
    $connectResult = Connect-PufferSearchAndDestroy -ConnectType 'Nam04'
    if ($connectResult -ne $null) {
        Write-Warning 'There was an issue connecting to ExchangeOnline.'
        $result -eq $false
    }

    # Gather data prior to processing
    if ($result -eq $null) {
        # We always want to know our domain name even if we don't need it
        if ($Domain) {$sender = $Domain} else {$sender = $From}

        # Let's do some quick validation
        if ($BlockHeader -and -not $Header) {
            $Header = Read-Host -Prompt "Please provide header text to block"
        }

        if ($BlockSubject -and -not $Subject) {
            $Subject = Read-Host -Prompt "Please provide subject text to block"
        }

        if ($BlockBody -and -not $Body) {
            $Body = Read-Host -Prompt "Please provide body text to block"
        }

        if ($BlockDomain -and -not $Domain) {
            $Domain = ($From -Split('@'))[1]
        }

        # Convert DateTimes into short date strings
        $kqlStartDate = $StartDate.ToShortDateString()
        Write-Verbose "${scriptName}: Start Date: $kqlStartDate"
        $kqlEndDate = $EndDate.ToShortDateString()
        Write-Verbose "${scriptName}: End Date: $kqlEndDate"

        # Generate our case name
        $caseName = New-PufferCaseName -From $sender -Disconnect:$False
        if (-not $CaseName) {
            Write-Warning "${scriptName}: Could not get a case name."
            $result = $false
        }
    }

    # Block the sender
    if ($result -eq $null) {
        # Block individual sender
        if ($BlockSender) {
            Write-Verbose "${scriptName}: Block Sender: $From"
            $blockResult = Start-PufferMailBlock -Sender $From
        }

        # Block an entire domain
        if ($BlockDomain) {
            Write-Verbose "${scriptName}: Block Domain: $Domain"
            $blockResult = Start-PufferMailBlock -Domain $Domain
        }

        # Block emails with specific subjects
        if ($BlockSubject) {
            Write-Verbose "${scriptName}: Block Subject: $Subject"
            $blockResult = Start-PufferMailBlock -Subject $Subject
        }

        # Block emails with specific body contents
        if ($BlockBody) {
            Write-Verbose "${scriptName}: Block Body: $Body"
            $blockResult = Start-PufferMailBlock -Body $Body
        }

        # Block emails with specific body contents
        if ($BlockHeader) {
            Write-Verbose "${scriptName}: Block Header: $Header"
            $blockResult = Start-PufferMailBlock -Header $Header
        }

        # Note errrors in blocking
        if ($blockResult -ne $null) {
            Write-Warning "There was an error applying the block."
        }
    }

    # Create and run the search
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Starting the search with CaseName: $caseName"
        $SearchResult = Start-PufferMailSearch -CaseName $caseName -From $sender -To $To -Subject $Subject -StartDate $kqlStartDate -EndDate $kqlEndDate
        if (-not $SearchResult) {
            Write-Warning 'There was a search issue.'
            $result = $false
        }

        # Stop pocessing if search returned no results
        $searchResult = Get-ComplianceSearch -Identity $caseName -ErrorAction SilentlyContinue
        if ($searchResult.Items -eq 0 -or $searchResult.Items -eq $null) {
            Write-Verbose "${scriptName}: No items returned by search. Nothing to do!"
            $result = $false
        }
    }

    # Generate the preview
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Starting the preview with CaseName: $caseName"
        $PreviewResult = Start-PufferMailSearchPreview -SearchName $CaseName
        if ($PreviewResult -eq $false) {
            Write-Warning 'There was a preview issue.'
            $result = $false
        }
    }

    # Provide user a clean out if the search was bad
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Verify that user is willing to delete."
        $userResponse = Get-UserResponse -Prompt "You have reviewed the search results and are ready to delete?: [y/n]"
        if (-not $userResponse) {
            Write-Warning 'Quitting without delete.'
            $result = $false
        }
    }

    # Complete the purge
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Starting the purge with CaseName: $caseName"
        $PurgeResult = Start-PufferMailPurge -SearchName $CaseName
        if (-not $PurgeResult) {
            Write-Warning 'There was a purge issue.'
            $result = $false
        }
    }

    # Disconnect
    Write-Verbose "${scriptName}: Disconnect from ExchangeOnline..."
    $disconnectResult = Disconnect-PufferSearchAndDestroy -ConnectType 'Nam04'
    if ($disconnectResult -ne $null) {
        Write-Warning "Remote sessions not fully disconnected."
    }

    Write-Verbose "${scriptName}: Completed at $(Get-Date)"
}