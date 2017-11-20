<#
    Solution: Citrix
    Purpose: Move DXPECORP users from DXPECOM group to DXPECORP group
    Version: 1.0 - 02/10/17

    Author: Andrew Ogden
    Email: andrew.ogden@dxpe.com
#>

param
(
    [string]$ComGroup,
    [string]$CorpGroup,
    [pscredential]$ComUser,
    [pscredential]$CorpUser
)

#Get DXPECOM group members
function getGroupMembers($gname)
{
    $thisgroup = "" | Select-Object Groupname,UMembers,GMembers
    $thisgroup.Groupname = $gname
    $thisgroup.UMembers=@()
    $thisgroup.GMembers=@()
    $thisgroup.UMembers = get-adgroupmember -server dxpe.com -identity $gname | ?{$_.objectClass -eq 'user'}
    $groups=get-adgroupmember -server dxpe.com -identity $gname | ?{$_.objectClass -eq 'group'}

    foreach($gmember in $groups)
    {
        write-host $gmember.name
        if ($gmember.name)
        {
            $childgroup=getGroupMembers $gmember.name
            $thisgroup.gMembers += $childgroup
        }
    }
    return $thisgroup
}

$ComGroupMembers = getGroupMembers "$ComGroup"
return $ComGroupMembers