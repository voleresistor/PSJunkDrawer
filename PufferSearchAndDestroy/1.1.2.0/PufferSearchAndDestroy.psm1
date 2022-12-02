<#
    Created 05/25/2021
    Updated 06/23/2021

    Changelog:
        1.1.0.4
            Modify Start-PufferSearchAndDestroy to stop processing if a search returns no items

        1.1.0.3
            Make Write-Host in Start-PufferComplianceSearchWait slightly more descriptive

        1.1.0.2
            Fix issue with script exiting following initial connection to ExchangeOnline

        1.1.0.1
            Fixed a bug causing a crash when calling Start-PufferSearchAndDestroy

        1.1.0.0:
            Verify that search returned results before attempting to start preview
            Rewrote function returns and error handling
            Scripts should generally be more robust now

        1.1.1.0:
            Added basic user mail export capabilities with
                Select-AdUser
                Start-TermedUserExport

        1.1.2.0:
            Expand mailbox export to convert mailbox to shared and remove O365 license
            Add function
                Remove-UserFromO365Group
#>

# ===================
# Internal Functions
# Not for export
# ===================
foreach ($ScriptFile in Get-ChildItem -Path "$PSScriptRoot\Scripts\Private" -Filter *.ps1) {
    . $ScriptFile.FullName
}

# Load each script in the Scripts folder. Individual functions are easier to maintain as scripts rather than
# all piled up in here.
foreach ($ScriptFile in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1) {
    . $ScriptFile.FullName
}
