function Add-ComputersToADGroup
{
    param
    (
        [Parameter(Mandatory=$false,Position=1)]
        [string]$GroupName = 'Bitlocker Devices',

        [Parameter(Mandatory=$false,Position=2)]
        [string]$SimpleMatch = '*dxpelt*',

        [Parameter(Mandatory=$true,Position=3)]
        [int]$NumberToAdd,

        [Parameter(Mandatory=$false,Position=4)]
        [switch]$WhatIf
    )

    # This is everyone who IS in the target group already
    $GroupMembers = Get-ADGroup -Filter {Name -eq $GroupName} | Get-ADGroupMember | Select-Object Name

    # Populate the list of all computers matching the simple match that AREN'T in the group
    $NonGroupMembers = @()
    Get-ADComputer -Filter {Name -like $SimpleMatch} | `
    Foreach-Object {
        if ($($GroupMembers.Name) -notcontains ($_.Name))
        {
            $NonGroupMembers += $_
        }
    }

    # Select a specified number of accounts from the non group members at random
    $AddToGroup = Get-Random -InputObject $NonGroupMembers -Count $NumberToAdd

    # Add the lotto winners to the group
    foreach ($c in $AddToGroup)
    {
        $c.Name
        if ($WhatIf)
        {
            Add-AdGroupMember $GroupName -Members $c.SamAccountName -WhatIf
        }
        else
        {
            Add-AdGroupMember $GroupName -Members $c.SamAccountName
        }
    }
}