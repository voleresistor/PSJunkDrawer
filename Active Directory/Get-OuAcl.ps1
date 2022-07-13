function Get-OuAcl {
    param (
        [Parameter (Mandatory=$true)]
        [string]$DistinguishedName
    )

    # Get ACL
    $thisAcl = (Get-Acl $DistinguishedName).Access

    # Our list
    $OuAcls = @()

    # Cycle through all ACLs, to build list
    foreach ($ac in $thisAcl) {
        # Our custom object
        # $objAcl = New-Object psobject
        # $objAcl | New-Member -MemberType NoteProperty -Name DistinguishedName -Value $DistinguishedName
        # $objAcl | New-Member -MemberType NoteProperty -Name IdentityReference -Value $($ac.IdentityReference)
        # $objAcl | New-Member -MemberType NoteProperty -Name ACLType -Value $($ac.AccessControlType)
        # $objAcl | New-Member -MemberType NoteProperty -Name IsInherited -Value $($ac.IsInherited)

        # The above method is the old way and is significantly slow than the new method
        $objAcl = [PSCustomObject]@{
            DistinguishedName = $DistinguishedName
            IdentityReference = $($ac.IdentityReference)
            ACLType = $($ac.AccessControlType)
            IsInherited =$($ac.IsInherited)
        }

        $OuAcls += $objAcl
    }
    
    return $OuAcls
}