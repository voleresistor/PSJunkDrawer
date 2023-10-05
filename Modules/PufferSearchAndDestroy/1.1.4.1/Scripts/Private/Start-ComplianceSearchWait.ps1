function Start-ComplianceSearchWait {
    <#
    .SYNOPSIS
    Waits for the compliance search with given CaseName to reach state 'Completed' while displaying status and elapsed time.
    .EXAMPLE
    Start-ComplianceSearchWait -CaseName 'PHISH_malicious@bad.com_05-24-21'
    .INPUTS
    See params
    .OUTPUTS
    Feedback from Compliance backend.
    .NOTES
    Andrew Ogden @ Puffer-Sweiven
    andrew.ogden@puffer.com
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CaseName,

        # 5 minute wait limit
        [Parameter(DontShow)]
        [int]$WaitStartLimit = 300,

        # 15 minute wait limit
        [Parameter(DontShow)]
        [int]$WaitEndLimit = 900
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
        $result -eq $false
    }

    if ($result -eq $null) {
        try {
            # When did we start?
            $searchStart = $(Get-Date)

            # Create but leave them blank for use in the loop
            $searchState = $Null
            $oldSearchState = $null

            Do {
                # Check our run time
                $waitSpan = New-TimeSpan -Start $searchStart -End (Get-Date)
                if ($WaitSpan.TotalSeconds -ge $WaitEndLimit) {
                    throw 'Timed out waiting for search completion.'
                }

                # Collect state and report no it
                $searchState = (Get-ComplianceSearch -Identity $CaseName -ErrorAction Stop).Status
                if ($searchState -ne $oldSearchState) {
                    Write-Verbose "${scriptName}: SearchState: $searchState"
                    $oldSearchState = $searchState
                }

                # Display the timer bar
                $statusTime = $($waitSpan.ToString() -Split('\.'))[0]
                Write-Progress -CurrentOperation $CaseName -Activity $searchState -Status $statusTime

                # Wait
                Start-Sleep -Seconds 1
            } Until ($searchState -eq "Completed")
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