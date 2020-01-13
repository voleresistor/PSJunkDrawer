Function Get-RegKeyProperties
{
    <#
    .Synopsis
    Simplifies grabbing reg key properties.
    
    .Description
    Collect properties for the specified reg key. By default hides PS* properties to reduce clutter and make it easier to find the information you're looking for.
    
    .Parameter RegKey
    The reg key to collect properties from.

    .Parameter ComputerName
    The remote computer to gather properties from.

    .Parameter All
    Return all properties, including PS* properties.
    
    .Example
    Get-RegKeyProperties -RegKey HKLM:\SOFTWARE\Microsoft\.NETFramework
    
    Collect properties from the given reg key
    #>
    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [string]$RegKey,

        [Parameter(Mandatory=$false,Position=2)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [switch]$All
    )

    # If not accessing the local computer test netconnection to verify availability
    if ($ComputerName -ne $env:COMPUTERNAME)
    {
        if (!(Test-NetConnection -ComputerName $ComputerName))
        {
            throw "Can't communicate with $ComputerName"
        }

        # Use Invoke-Command to create a temporary PS session in which to gather the reg key properties
        $scriptBlock = {
            param($RegKey)
            Get-ItemProperty -Path $RegKey
        }
        $regProps = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $RegKey
    }
    else
    {
        # Just grab reg key properties from the local machine
        $regProps = Get-ItemProperty -Path $RegKey
    }

    # Just crap all properties out if the user wants them for some reason
    if ($All)
    {
        return $regProps
    }

    # Otherwise we gather the  names of the interesting properties
    $propNames = ($regProps | get-member | Where-Object {$_.MemberType -eq 'NoteProperty'} | Where-Object {($_.Name -notlike "PS*") -and ($_.Name -ne 'RunspaceId')}).Name

    # Finally, pass those properties to the user
    $regProps | Select-Object -Property $propNames
}
