function Start-PufferMailSearchPreview {
    <#
    .SYNOPSIS
    Start a preview action following the end of a search. Requires a valid search case name.
    .DESCRIPTION
    Start a preview action following the end of a search. Requires a valid search case name.
    .EXAMPLE
    Start-PufferMailSearchPreview -SearchName ‘Search1’
    Start a preview for the search named ‘Search1.’
    .PARAMETER SearchName
    The name of an existing search case.
    .NOTES
    Andrew Ogden @ Puffer-Sweiven
    Matthew Silcox @ Catapult Systems
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$SearchName
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

    if ($result -eq $null) {
        # Build our action name
        $caseName = "${SearchName}_Preview"
        Write-Verbose "${scriptName}: Preview action name: $caseName"

        # Verify that we can find the search and it returned greater than 0 items
        $searchItems = (Get-ComplianceSearch -Identity $SearchName).Items
        if ($searchItems -and $searchItems -gt 0) {
            Write-Verbose "${scriptName}: Found $($searchItems.ToString()) items. Starting preview..."
            # Start the new action.
            # Signal a failure to the caller if something went wrong
            try {
                Write-Verbose "${scriptName}: Starting the preview..."
                New-ComplianceSearchAction -SearchName $SearchName -Preview -ErrorAction Stop
            }
            catch {
                Write-Warning $_.Exception.Message
                $result = $false
                break
            }

            # Show off what's going on until complete
            Start-ComplianceSearchActionWait -CaseName $caseName
        }
        else {
            Write-Verbose "${scriptName}: Search not found or no search items returned."
        }
    }

    # If we were called from Start-PufferSearchAndDestroy then let that know we succeeded
    # Otherwise, assume we were run standalone and disconnect
    if ($scriptOrigin -eq 'Internal') {
        return $result
    }
    else {
        Write-Verbose "${scriptName}: Disconnect from ExchangeOnline..."
        Disconnect-PufferSearchAndDestroy -ConnectType 'Nam04'
    }
}