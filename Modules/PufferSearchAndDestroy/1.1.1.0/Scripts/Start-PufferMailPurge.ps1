function Start-PufferMailPurge {
    <#
    .SYNOPSIS
    Begin a HardDelete type purge action on the results of a search.
    .DESCRIPTION
    Begin a HardDelete type purge action on the results of a search.
    .EXAMPLE
    Start-PufferMailPurge -SearchName ‘Search1’
    Start a mail purge on the search named ‘Search1.’
    .PARAMETER SearchName
    The name of an existing search case.
    .NOTES
    Andrew Ogden @ Puffer-Sweiven
    Matthew Silcox @ Catapult Systems
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$SearchName,

        [Parameter(Mandatory=$false)]
        [switch]$Confirm
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

    # Create and start the purge action
    if ($result -eq $null) {
        # Build our action name
        $caseName = "${SearchName}_Purge"
        Write-Verbose "${scriptName}: Purge action name: $caseName"

        # Start the new action.
        # Signal a failure to the caller if something went wrong
        try {
            Write-Verbose "${scriptName}: Starting the purge..."
            New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete -Confirm:$Confirm -ErrorAction Stop
        }
        catch {
            Write-Warning $_.Exception.Message
            $result = $false
            break
        }

        # Show off what's going on until complete
        Start-ComplianceSearchActionWait -CaseName $CaseName
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