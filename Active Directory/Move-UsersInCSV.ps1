function Move-UsersInCsv
{
    [cmdletbinding()]
    param
    (
        [string[]]$RemoveGroup,

        [string[]]$AddGroup,

        [string]$InputCsv
    )

    $inputFile = Import-Csv -Delimiter "," -Path $InputCsv -Header "UserName"

    # Simple function to gather an array of groups
    function Get-GroupList
    {
        param
        (
            [string[]]$Groups
        )

        $arrGroups = @()
        foreach ($g in $AddGroup)
        {
            $objGroup = Get-AdGroup -Filter {Name -eq $g}

            if ($objGroup)
            {
                Write-Verbose "Found Add Group: $($objGroup.Name)"
                $arrGroups += $objGroup
            }
            else
            {
                Write-Verbose "Group not found: $g"
            }

            Clear-Variable objGroup -ErrorAction SilentlyContinue
        }

        return $arrGroups
    }

    # Find our groups
    $arrAddGroups = Get-GroupList -Groups $AddGroup
    $arrRemGroups = Get-GroupList -Groups $RemoveGroup

    # Gather the list of users
    $arrUsers = @()
    foreach ($u in $inputFile.UserName)
    {
        $objUser = Get-ADUser -Filter {Name -eq $u}

        if ($objUser)
        {
            Write-Verbose "Found user: $($objUser.SamAccountName)"
            $arrUsers += $objUser
        }
        else
        {
            Write-Verbose "User not found: $u"
        }
    }

    # Update Add Groups
    foreach ($g in $arrAddGroups)
    {
        Add-AdGroupMember -Identity $g -Members $arrUsers
    }

    # Update Remove Groups
    foreach ($g in $arrRemGroups)
    {
        Remove-AdGroupMember -Identity $g -Members $arrUsers
    }
}