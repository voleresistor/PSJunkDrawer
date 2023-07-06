function Set-TermedUserDelegation {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser]$UserAdObj,

        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser]$DelegateTo
    )

    # Connect to Exchange 365 PowerShell
    if ($null -ne (Connect-PufferSearchAndDestroy -ConnectType 'Office')) {
        Write-Error "Failed to connect to Office PowerShell!"
        return 1
    }

    # Set the delegation
    try {
        if ($PSCmdlet.ShouldProcess($($UserAdObj.mail))) {
            Add-MailboxPermission -Identity $($UserAdObj.mail) -User $($DelegateTo.mail) -AccessRights 'FullAccess' -InheritanceType 'All'
        }
    }
    catch {
        # Disconnect from Office PowerShell
        Disconnect-PufferSearchAndDestroy

        #Write-Error $_.Exception.Message
        Write-Warning "${scriptName}: Failed to set delegation for $($UserAdObj.mail)."
        return 1
    }

    # Disconnect from Office PowerShell
    Disconnect-PufferSearchAndDestroy
}