function Convert-MailboxToShared {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.ActiveDirectory.Management.ADUser]$UserAdObj
    )

    # Connect to Exchange 365 PowerShell
    if ($null -ne (Connect-PufferSearchAndDestroy -ConnectType 'Office')) {
        Write-Error "Failed to connect to Office PowerShell!"
        return 1
    }

    # Convert the mailbox to shared
    try {
        if ($PSCmdlet.ShouldProcess($($UserAdObj.mail))) {
            Get-Mailbox -Identity $($UserAdObj.mail) | Set-Mailbox -Type Shared
        }
    }
    catch {
        # Disconnect from Office PowerShell
        Disconnect-PufferSearchAndDestroy

        #Write-Error $_.Exception.Message
        Write-Warning "${scriptName}: Failed to convert $($UserAdObj.mail) to shared mailbox."
        return 1
    }

    # Disconnect from Office PowerShell
    Disconnect-PufferSearchAndDestroy
}