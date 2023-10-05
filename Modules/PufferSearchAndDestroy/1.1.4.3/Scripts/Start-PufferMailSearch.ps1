function Start-PufferMailSearch {
    <#
    .SYNOPSIS
    Create and start a new mail search.
    .DESCRIPTION
    Create and start a new mail search. It can take several minutes to start and complete a search.
    .EXAMPLE
    Start-PufferMailSearch -CaseName ‘Search1’ -From ‘info@spammer.com’
    Start a search for info@spammer.com with case name ‘Search1 in all mailboxes with no date range.
    .EXAMPLE
    Start-PufferMailSearch -CaseName ‘Search1’ -From ‘info@spammer.com’ -Location ‘user@puffer.com’
    Start a search for info@spammer.com with case name ‘Search1’ with no date range in only the mailbox belonging to user@puffer.com.
    .PARAMETER CaseName
    The search display name.
    .PARAMETER From
    The sender email address for which to search.
    .PARAMETER Location
    The mailbox in which to search. Can be either ‘All’ or a specific mailbox name.
    .PARAMETER StartDate
    The earliest date from which to search.
    .PARAMETER EndDate
    The latest date up to which to search for emails.
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
        [Parameter(Mandatory=$true,Position=1)]
        [string]$From,

        [Parameter(Mandatory=$false)]
        [string]$CaseName,

        [Parameter(Mandatory=$false)]
        [string]$Description,

        [Parameter(Mandatory=$false)]
        [string]$Location = 'All',

        [Parameter(Mandatory=$false)]
        [string]$StartDate,

        [Parameter(Mandatory=$false)]
        [string]$EndDate,

        [Parameter(Mandatory=$false)]
        [string]$Subject,

        [Parameter(Mandatory=$false)]
        [string]$To,

        # 5 minute wait limit
        [Parameter(DontShow)]
        [int]$WaitLimit = 300,

        [Parameter(DontShow)]
        [int]$MaxTries = 3
    )

    # What's the status of this run?
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # Make sure we're connected to ExchangeOnline
    Write-Verbose "${scriptName}: Verify connection to ExchangeOnline..."
    $connectResult = Connect-PufferSearchAndDestroy -ConnectType 'Compliance'
    if ($connectResult -ne $null) {
        Write-Warning 'There was an issue connecting to ExchangeOnline.'
        $result = $false
    }

    # We need a description and casename
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Verify description and case name."
        if (-not $Description) {
            $Description = $From
        }

        # Make sure we have a casename
        if (-not $CaseName) {
            $CaseName = New-PufferCaseName -From $From -Disconnect:$false
            if (-not $CaseName) {
                Write-Warning "${scriptName}: Could not get a case name."
                $result = $false
            }
        }
    }

    # Build the query
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Build the query..."
        $MatchQuery = "From:$From"
        if ($StartDate) {
            $MatchQuery += " AND Received>=$StartDate"
        }

        if ($EndDate) {
            $MatchQuery += " AND Received<=$EndDate"
        }

        if ($Subject) {
            $MatchQuery += " AND Subject:`"$Subject`""
        }

        if ($To) {
            $MatchQuery += " AND recipients:$To"
        }

        # Verbosely report query as well as printing it to the console
        Write-Verbose "${scriptName}: QUERY: $MatchQuery"
    }

    # Create the search, wait for it to be, then start it.
    # Signal a failure to the caller if something went wrong
    if ($result -eq $null) {
        Write-Verbose "${scriptName}: Verify connection to ExchangeOnline..."
        try {
            # Create the search
            Write-Verbose "${scriptName}: Creating the search..."
            New-ComplianceSearch -Name $CaseName -Description $Description -ExchangeLocation $Location -ContentMatchQuery $MatchQuery -ErrorAction Stop

            # Wait up to 5 minutes for the search to exist 
            $waitStart = Get-Date
            while (-not (Get-ComplianceSearch -Identity $CaseName -ErrorAction SilentlyContinue)) {
                $waitSpan = New-TimeSpan -Start $waitStart -End (Get-Date)
                if ($($waitSpan.Seconds) -ge $WaitLimit) {
                    throw 'Timed out waiting for case creation.'
                }

                $waitTime = ($waitSpan.ToString() -Split('\.'))[0]
                Write-Progress -CurrentOperation $CaseName -Activity 'Waiting for case creation...' -Status $waitTime
                Start-Sleep -Seconds 1
            }

            # Wait for the search to "settle" before starting it
            # Sometimes invoking the search immediately results in strange behvior
            Write-Verbose "$($scriptName): Waiting before starting search..."
            $waitLength = 15
            $waitStart = (Get-Date).AddSeconds($WaitLength)
            do {
                $waitSpan = New-TimeSpan -Start (Get-Date) -End $waitStart
                $waitTime = ($waitSpan.ToString() -Split('\.'))[0]
                Write-Progress -CurrentOperation $CaseName -Activity "Waiting $($WaitLength.ToString()) seconds for search to settle..." -SecondsRemaining $waitSpan.TotalSeconds -Status 'Waiting'
                Start-Sleep -Seconds 1
            } until ($($waitSpan.TotalSeconds) -le 0)

            # Start the search
            $tryCount = 1
            do {
                # Exit if we can't get the search to run successfully
                $tryCount++
                if ($tryCount -gt $MaxTries) {
                    throw "Maximum search attempts reached!"
                }

                Write-Verbose "${scriptName}: Starting the search..."
                Start-ComplianceSearch -Identity $caseName -ErrorAction SilentlyContinue

                $jobStartTime = (Get-ComplianceSearch -Identity $caseName).JobStartTime
                Write-Verbose "${scriptName}: Job started at $jobStartTime"

                $searchErr = Start-ComplianceSearchWait -CaseName $CaseName
            } until ($searchErr -eq $null)

            $searchResult = Get-ComplianceSearch -Identity $caseName
            Write-Verbose "${scriptName}: Search completed at $($searchResult.JobEndTime)"
            Write-Verbose "${scriptName}: Items found: $($searchResult.Items)"
            Write-Verbose "${scriptName}: Errors: $($searchResult.Errors)"
        }
        catch {
            Write-Error $_.Exception.Message
            $result = $false
        }
    }

    # If we were called from Start-PufferSearchAndDestroy then let that know we succeeded
    # Otherwise, assume we were run standalone and disconnect
    if ($scriptOrigin -eq 'Internal') {
        return $result
    }
    else {
        Write-Verbose "${scriptName}: Disconnect from ExchangeOnline..."
        Disconnect-PufferSearchAndDestroy -ConnectType 'Compliance'
    }
}