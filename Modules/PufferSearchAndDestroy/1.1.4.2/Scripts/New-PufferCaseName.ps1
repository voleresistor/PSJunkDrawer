function New-PufferCaseName {
    <#
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$From,

        [Parameter(DontShow)]
        [switch]$Disconnect = $True
    )

    # What's the status of this run?
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # Blank casename
    $caseName = $null

    # Make sure we're connected to ExchangeOnline
    Write-Verbose "${scriptName}: Verify connection to ExchangeOnline..."
    $connectResult = Connect-PufferSearchAndDestroy -ConnectType 'Compliance'
    if ($connectResult -ne $null) {
        Write-Warning 'There was an issue connecting to ExchangeOnline.'
        $result -eq $false
    }

    # Build our final casename
    if ($result -eq $null) {
        # Build an initial casename
        $CaseNum = 1
        $CaseStr = $CaseNum.ToString().PadLeft(2, '0')
        $CaseName = "PHISH_${From}_$(Get-Date -Uformat '%m-%d-%y')_$CaseStr"

        # Increment the final number until we get a valid one
        while (Get-ComplianceSearch -Identity $CaseName -ErrorAction SilentlyContinue) {
            $CaseNum++
            $CaseStr = $CaseNum.ToString().PadLeft(2, '0')
            $CaseName = "PHISH_${From}_$(Get-Date -Uformat '%m-%d-%y')_$CaseStr"
        }

        # Tell the world about our case
        Write-Verbose "${scriptName}: Casename: $CaseName"
        Write-Host $CaseName

        # If we were called from Start-PufferSearchAndDestroy then let that know we succeeded
        # Otherwise, assume we were run standalone and disconnect
        if ($scriptOrigin -ne 'Internal') {
            Write-Verbose "${scriptName}: Disconnect from ExchangeOnline..."
            Disconnect-PufferSearchAndDestroy -ConnectType 'Compliance'
        }
    }

    return $CaseName
}