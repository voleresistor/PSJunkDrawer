function Get-ComputerDomain
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ComputerName
    )
    <#
    .SYNOPSIS
    Resolve domain name from unqualified computer name.
    
    .DESCRIPTION
    This function relies on working DNS. A FQDN is resolved for the given name and a custom object containing the computer name and domain is returned.
    
    .PARAMETER ComputerName
    Name of the computer to resolve.
    
    .EXAMPLE
    Get-ComputerDomain -ComputerName pc01
    #>

    # Get the FQDN via DNS lookup and return $false if it can't be found
    try
    {
        $Resolve = Resolve-DnsName -Name $ComputerName -ErrorAction Stop
    }
    catch [System.ComponentModel.Win32Exception]
    {
        return $false
    }

    # Some simple string editing to return a neatly packaged object
    $result = New-Object -TypeName PSObject
    $result | Add-Member -MemberType NoteProperty -Name Name -Value ($Resolve.Name -split ('\.'))[0]
    $result | Add-Member -MemberType NoteProperty -Name Domain -Value ($Resolve.Name -split ("$($result.Name)\."))[1]

    return $result
}