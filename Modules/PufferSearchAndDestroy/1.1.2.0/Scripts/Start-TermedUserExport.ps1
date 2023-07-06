function Start-TermedUserExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=1, ParameterSetName='UserName')]
        [string]$UserName,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName='SAM')]
        [string]$SamAccountName,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName='UPN')]
        [string]$UserPrincipalName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$CaseNumber,

        [Parameter(Mandatory=$false)]
        [System.IO.DirectoryInfo]$Root = $(Get-Item -Path '\\sta-fs-0001\TermedUsers')
    )

    #Requires -Modules ActiveDirectory

    # Start by trying to get a user from the input
    if ($UserName) {
        $userAdObj = Select-AdUser -UserName $UserName
    }
    elseif ($SamAccountName) {
        $userAdObj = Get-AdUser -Identity $samAccountName -Properties mail,employeeType -ErrorAction SilentlyContinue
    }
    elseif ($UserPrincipalName) {
        $userAdObj = Get-AdUser -Filter {UserPrincipalName -eq $UserPrincipalName} -Properties mail,employeeType -ErrorAction SilentlyContinue
    }
    else {
        Write-Error "Please select only one of -UserName, -SamAccountName, -UserPrincipalName"
        return 1
    }

    # Verify that we got a single user
    if ($userAdObj.Count -eq 0) {
        Write-Error "Unable to find a matching user."
        return 1
    }
    if ($userAdObj.Count -gt 1) {
        Write-Error "More than one matching user found."
        return 1
    }

    # Connect to Exchange 365 PowerShell
    if ((Connect-PufferSearchAndDestroy -ConnectType 'Office') -ne $null) {
        Write-Error "Failed to connect to Office PowerShell!"
        return 1
    }

    # Convert the mailbox to shared
    try {
        Get-Mailbox -Identity $($userAdObj.mail) | Set-Mailbox -Type Shared
    }
    catch {
        #Write-Error $_.Exception.Message
        Write-Warning "${scriptName}: Failed to convert $($userAdObj.mail) to shared mailbox."
    }

    # Disconnect from Office PowerShell
    Disconnect-PufferSearchAndDestroy

    # Connect to Compliance and Security PowerShell
    if ((Connect-PufferSearchAndDestroy -ConnectType 'Nam04') -ne $null) {
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
    Write-Verbose "${scriptName}: Waiting 30 seconds for search to fully complete..."
    Start-Sleep -Seconds 30
    Write-Verbose "${scriptName}: Creating the export..."
    $NewExport = New-ComplianceSearchAction -SearchName $caseName -Export -ExchangeArchiveFormat 'PerUserPst' -RetryOnError

    # Disconnect from Compliance and Security PowerShell
    Disconnect-PufferSearchAndDestroy

    # Remove the user's license groups
    $arrUserGroups = $userAdObj | Get-ADPrincipalGroupMembership
    foreach ($objGroup in $arrUserGroups) {
        Remove-UserFromO365Group -TargetUser $userAdObj -TargetGroup $objGroup
    }
}