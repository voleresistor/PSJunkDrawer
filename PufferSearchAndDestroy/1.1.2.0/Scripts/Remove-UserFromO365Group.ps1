function Remove-UserFromO365Group {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [Microsoft.ActiveDirectory.Management.ADUser]$TargetUser,

        [Parameter(Mandatory=$true, Position=2)]
        [Microsoft.ActiveDirectory.Management.ADGroup]$TargetGroup
    )

    # Define O365 groups
    $arrRemoveGroups = @(
        'O365 - Audio - Chile',
        'O365 - Audio - Colombia',
        'O365 - Audio - Ecuador',
        'O365 - Audio - Peru',
        'O365 - Audio - Test Users',
        'O365 - Audio - US',
        'O365 - Audio - Venezuela',
        'O365 - E3 License - M3',
        'O365 - E5 License',
        'O365 - F3 License',
        'O365 - Power Automate Free',
        'O365 - PowerBI Free',
        'O365 - Project Plan 3',
        'O365 - Project Plan 5',
        'O365 - Security E3',
        'O365 - Security E5',
        'O365 - Visio'
    )

    # Check and remove the user
    if ($arrRemoveGroups -contains $($TargetGroup.Name)) {
        Write-Verbose "${scriptName}: Removing $($TargetUser.Name) from $($TargetGroup.Name)"
        try {
            Remove-ADGroupMember -Identity $TargetGroup -Members $TargetUser -Confirm:$false
        }
        catch {
            # Write error and return $false to represent the failure
            Write-Error $_.Exception.Message
            #return $false
        }
    }
    else {
        Write-Verbose "${scriptName}: $($TargetUser.Name) not in $($TargetGroup.Name)"
    }

    # Return true if we made it this far
    #return $true
}