function Set-TermedUserOOO {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser]$UserAdObj,

        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser]$MailTo,

        [Parameter(Mandatory=$false)]
        [switch]$KeepConnectionOpen
    )

    # Build new OOO message from variables
    $strNewMessage = "$($UserAdObj.GivenName) $($UserAdObj.Surname) is no longer with Puffer. Please contact $($MailTo.GivenName) $($MailTo.Surname) at $($MailTo.mail)."

    # Connect to Exchange 365 PowerShell
    if ($null -ne (Connect-PufferSearchAndDestroy -ConnectType 'Exchange')) {
        Write-Error "Failed to connect to Office PowerShell!"
        return 1
    }

    # Set the OOO message
    try {
        if ($PSCmdlet.ShouldProcess($($UserAdObj.mail))) {
            Set-MailboxAutoReplyConfiguration -Identity $($UserAdObj.mail) -AutoReplyState 'Enabled' -InternalMessage $strNewMessage -ExternalMessage $strNewMessage | Out-Null
        }
    }
    catch {
        # Disconnect from Office PowerShell
        Disconnect-PufferSearchAndDestroy

        #Write-Error $_.Exception.Message
        Write-Warning "${scriptName}: Failed to set out of office message for $($UserAdObj.mail)."
        return 1
    }

    # Disconnect from Office PowerShell
    if (-not $KeepConnectionOpen) {
        Disconnect-PufferSearchAndDestroy
    }
}