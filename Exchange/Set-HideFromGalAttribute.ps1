function Set-HideFromGalAttribute {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true,
            HelpMessage="A single or array of AD user objects queried using Get-ADUser"
        )]
        [Object[]]$Identity,

        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Whether to enable (True) or disable (False) the hide from addreess lists attribute."
        )]
        [bool]$Enable = $True
    )

    foreach ($user in $Identity) {
        if ($PSCmdlet.ShouldProcess($user.DistinguishedName)) {
            Set-ADObject -Identity $user.DistinguishedName -Replace @{msExchHideFromAddressLists=$Enable} -Confirm:$False
        }
    }
}

<#
    **** Usage ****

    Hide the user pwhela01 from the GAL
    PS C:\> Get-ADUser -Identity pwhela01 | Set-HideFromGalAttribute

    Unhide the user pwhela01 from the GAL
    PS C:\> Get-ADUser -Identity pwhela01 | Set-HideFromGalAttribute -Enable $False

    Ensure that all disabled users in an OU are hidden from the GAL
    ps c:\> Get-ADUser -Filter {Enabled -eq $false} -SearchBase 'OU=Disabled Users,DC=puffer,DC=com' | Set-HideFromGalAttribute
    
#>