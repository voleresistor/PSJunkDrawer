function Update-AdHomedirs
{
    param
    (
        [cmdletbinding()]

        [Parameter(Mandatory=$true, Position=1)]
        [string]$HomedirPrefix,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$HomedirReplace,

        [Parameter(Mandatory=$false)]
        [string]$SurnamePattern,

        [Parameter(Mandatory=$false)]
        [string]$GivenNamePattern,

        [Parameter(Mandatory=$false)]
        [string]$Domain = 'dxpe.corp'
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
    If ($SurnamePattern -and !$FirstNamePattern)
    {
        $LDAPFilter = "(&(objectCategory=person)(objectClass=user)(sn=$SurnamePattern))"
    }
    elseif (!$SurnamePattern -and $FirstNamePattern)
    {
        $LDAPFilter = "(&(objectCategory=person)(objectClass=user)(givenName=$FirstNamePattern))"
    }
    else
    {
        Write-Host "Please provide either -SurnamePattern or -GivenNamePattern"
        exit 1
    }

    # Get list of users matching search strings
    $Users = Get-AdUser -LDAPFilter $LDAPFilter -Properties HomeDirectory -Server $Domain | Where-Object {$_.HomeDirectory -like $HomedirPrefix}
    return $Users