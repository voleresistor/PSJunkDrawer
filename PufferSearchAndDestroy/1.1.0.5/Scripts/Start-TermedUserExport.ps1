function Start-TermedUserExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [Microsoft.ActiveDirectory.Management.ADUser]$TargetUser,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$CaseNumber,

        [Parameter(Mandatory=$false)]
        [System.IO.DirectoryInfo]$Root = $(Get-Item -Path '\\sta-fs-0001\TermedUsers')
    )

    # Connect to Compliance and Security PowerShell
    if ((Connect-PufferSearchAndDestroy -ConnectType 'Nam04') -ne $null) {
        Write-Error "Failed to connect to Compliance and Security PowerShell!"
        exit 1
    }

    # What's the status of this run?
    # Non-null states are considered errors
    $result = $null

    # Who are we?
    $scriptName = $MyInvocation.MyCommand.Name

    # Who called us?
    $scriptOrigin = $MyInvocation.CommandOrigin

    # Create the case
    Write-Verbose "${scriptName}: Creating the case..."
    $CaseName = "IR$CaseNumber - $($TargetUser.Name)"
    $NewCase = New-ComplianceCase -Name $CaseName

    # Wait 15 seconds for the case to exist
    Start-Sleep -Seconds 15

    # Create the search
    Write-Verbose "${scriptName}: Creating the search..."
    $NewSearch = New-ComplianceSearch -Case $CaseName -Name $CaseName -ExchangeLocation $($TargetUser.mail)

    # Wait 15 seconds for the case to exist
    Write-Verbose "${scriptName}: Waiting for search creation..."
    Start-Sleep -Seconds 15

    # Start the search
    Write-Verbose "${scriptName}: Starting the search..."
    Start-ComplianceSearch -Identity $CaseName
    
    # Wait for the search to complete
    Write-Verbose "${scriptName}: Waiting for the search to complete..."
    $SearchResult = Start-ComplianceSearchWait -CaseName $($NewSearch.Name)    

    # Start the export
    Write-Verbose "${scriptName}: Creating the export..."
    $NewExport = New-ComplianceSearchAction -SearchName $caseName -Export -ExchangeArchiveFormat 'PerUserPst'

    # Finish up
    Disconnect-PufferSearchAndDestroy
}