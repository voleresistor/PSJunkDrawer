function Get-LaptopsOutsideBitlockerGroup
{
    param
    (
        [string]$GroupName = 'Bitlocker Devices',

        [string]$SimpleMatch = '*dxpelt*'
    )

    $GroupMembers = Get-ADGroup -Filter {Name -eq $GroupName} | Get-ADGroupMember | Select-Object Name

    Get-ADComputer -Filter {Name -like $SimpleMatch} | `
    Foreach-Object {
        if ($($GroupMembers.Name) -notcontains ($_.Name))
        {
            $_.Name
        }
    }
}