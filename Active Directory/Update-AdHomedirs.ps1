function Update-AdHomedirs
{
    param
    (
        [cmdletbinding()]

        [Parameter(Mandatory=$true, Position=1)]
        [string]$HomedirPrefix,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$HomedirReplace,

        [Parameter(Mandatory=$true)]
        [string]$SurnameStart,

        [Parameter(Mandatory=$true)]
        [string]$SurnameEnd,

        [Parameter(Mandatory=$false)]
        [string]$Domain = 'dxpe.corp',

        [Parameter(Mandatory=$false)]
        [switch]$Update
    )
    function Double-Backslash
    {
        param
        (
            [Parameter(Mandatory=$true, Position=1)]
            [string]$in
        )
        <#
        Double backslashes in the provided string to make them compatible with
        Regex style searches.
        #>

        return $in -replace('\\', '\\')
    }
    
    # Create LDAP filter string
    $LDAPFilter = "(&(objectCategory=person)(objectClass=user)(sn>=$SurnameStart*)(sn<=$SurnameEnd*))"
    # Get list of users matching search strings
    $Users = Get-AdUser -LDAPFilter $LDAPFilter -Properties HomeDirectory -Server $Domain | Where-Object {$_.HomeDirectory -like "$HomedirPrefix*"}
    #return $Users

    if ($Update)
    {
        foreach ($u in $Users)
        {
            $NewPath = $($u.HomeDirectory) -replace ($(Double-Backslash $HomedirPrefix), $HomedirReplace)

            Write-Verbose "Changing user $($u.Name) home directory from $($u.HomeDirectory) to $NewPath"
            try
            {
                Set-ADUser -Identity $u -HomeDirectory $NewPath #-WhatIf
            }
            catch
            {
                Write-Verbose "Failed to update user $($u.Name)"
                return 1
            }
            Write-Verbose "Successfully modified user $($u.Name)'s home directory"

            Clear-Variable NewPath
        }
    }
    else
    {
        return $Users
    }
}