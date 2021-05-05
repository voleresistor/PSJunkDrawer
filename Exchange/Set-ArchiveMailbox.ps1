function Set-ArchiveMailbox
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$MailName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$Operation,

        [Parameter(Mandatory=$true)]
        [string]$ConnectAccount
    )

    begin
    {
        $ArchiveGuid = "00000000-0000-0000-0000-000000000000"
        $affirmative = @('y', 'yes')

        try
        {
            Import-Module -Name ExchangeOnlineManagement -ErrorAction Stop
            Connect-ExchangeOnline -UserPrincipalName $ConnectAccount -ErrorAction Stop
        }
        catch
        {
            Write-Error "Something happened while connecting to ExchangeOnline."
            Write-Error "Message: [$($_.Exception.Message)]"
            exit(1)
        }
    }
    
    process
    {
        # Verify account exists
        $MailAccount = Get-Mailbox -Identity $MailName -Filter {RecipientTypeDetails -eq 'UserMailbox'} -ErrorAction SilentlyContinue
        if (!($MailAccount))
        {
            Write-Warning "No mailbox found for $MailName"
            exit
        }

        # Attempting to enable a mailbox
        if ($Operation -eq 'Enable' -AND $MailAccount.ArchiveGuid -eq $ArchiveGuid)
        {
            Enable-Mailbox -Identity $MailName -Archive -WhatIf
        }
        elseif ($Operation -eq 'Enable' -AND $MailAccount.ArchiveGuid -ne $ArchiveGuid)
        {
            Write-Warning "Archive mailbox already enabled for $MailName"
        }

        # Attempting to disable a mailbox
        elseif ($Operation -eq 'Disable'-AND $MailAccount.ArchiveGuid -ne $ArchiveGuid)
        {
            Write-Warning "Disabling an archive mailbox can potentially lead to data loss. Are you SURE you want to do this?"
            if ($affirmative.Contains((Read-Host -Prompt "Are you sure? [y/N]").ToLower()))
            {
                Disable-Mailbox -Identity $MailName -Archive -Whatif
            }
            else
            {
                Write-Warning "Canceling change."
            }
        }
        elseif ($Operation -eq 'Disable'-AND $MailAccount.ArchiveGuid -eq $ArchiveGuid)
        {
            Write-Warning "Archive isn't enabled for $MailName"
        }
    }

    end
    {
        Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore
    }
}