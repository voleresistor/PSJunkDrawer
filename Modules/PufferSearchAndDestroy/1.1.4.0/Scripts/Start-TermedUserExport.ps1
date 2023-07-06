function Start-TermedUserExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$SamAccountName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$CaseNumber,

        [Parameter(Mandatory=$false, Position=3)]
        [string[]]$DelegateTo,

        [Parameter(Mandatory=$false, Position=4)]
        [string]$MailTo,

        [Parameter(Mandatory=$false)]
        [System.IO.DirectoryInfo]$Root = $(Get-Item -Path '\\sta-fs-0001\TermedUsers')
    )

    #Requires -Modules ActiveDirectory

    # Start by trying to get users from the input
    $userAdObj = Get-AdUser -Identity $samAccountName -Properties mail,employeeType -ErrorAction SilentlyContinue

    if ($DelegateTo) {
        $delegateToObj = @()
        foreach ($o in $DelegateTo) {
            $delegateToObj += Get-AdUser -Identity $o -Properties mail,employeeType -ErrorAction SilentlyContinue
        }
    }

    if ($MailTo) {
        $mailToObj = Get-AdUser -Identity $MailTo -Properties mail,employeeType -ErrorAction SilentlyContinue
    }

    # convert mailbox to shared type
    if ($null -ne (Convert-MailboxToShared -UserAdObj $userAdObj -KeepConnectionOpen)) {
        Write-Error "Failed to convert mailbox to shared."
    }

    # Add delegations
    if ($delegateToObj) {
        foreach ($dObj in $delegateToObj) {
            if ($null -ne (Set-TermedUserDelegation -UserAdObj $userAdObj -DelegateTo $dObj -KeepConnectionOpen)) {
                Write-Error "Failed to delegate to $($dObj.UserPrincipalName)."
            }
        }
    }

    # Set OOO message
    if ($mailToObj) {
        if ($null -ne (Set-TermedUserOOO -UserAdObj $userAdObj -MailTo $mailToObj)) {
            Write-Error "Failed to set out of office message."
        }
    }

    # Connect to Compliance and Security PowerShell
    if ($null -ne (Connect-PufferSearchAndDestroy -ConnectType 'Compliance')) {
        Write-Error "Failed to connect to Compliance and Security PowerShell!"
        return 1
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
    $CaseName = "IR$CaseNumber - $($userAdObj.Name)"
    $NewCase = New-ComplianceCase -Name $CaseName

    # Wait 15 seconds for the case to exist
    Start-Sleep -Seconds 15

    # Create the search
    Write-Verbose "${scriptName}: Creating the search..."
    $NewSearch = New-ComplianceSearch -Case $CaseName -Name $CaseName -ExchangeLocation $($userAdObj.mail)

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
    # Write-Verbose "${scriptName}: Waiting 30 seconds for search to fully complete..."
    # Start-Sleep -Seconds 30
    Write-Verbose "${scriptName}: Creating the export..."
    $NewExport = New-ComplianceSearchAction -SearchName $caseName -Export -ExchangeArchiveFormat 'PerUserPst'

    # Disconnect from Compliance and Security PowerShell
    Disconnect-PufferSearchAndDestroy

    # Remove the user's license groups
    $arrUserGroups = $userAdObj | Get-ADPrincipalGroupMembership
    foreach ($objGroup in $arrUserGroups) {
        Remove-UserFromO365Group -TargetUser $userAdObj -TargetGroup $objGroup
    }
}