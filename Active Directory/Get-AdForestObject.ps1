function Get-ADForestObject
{
    <#
    .SYNOPSIS
    Get information about the specified forest.
    
    .DESCRIPTION
    Use .NET objects to gather detailed forest information.
    
    .PARAMETER ForestName
    FQDN of the target forest. If not specified, the current forest is used.
    
    .PARAMETER Credential
    A PSCredential object containing to be used to logon to the remote server or domain.
    
    .EXAMPLE
    Get-ADForestObject

    Get forest info for the current forest.
    
    .NOTES
    Borrowed from Edge Pereira at http://www.superedge.net/2012/09/how-to-get-ad-forest-in-powershell.html
    #>
    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string]$ForestName,

        [Parameter(Mandatory=$false, Position=2)]
        [System.Management.Automation.PsCredential]$Credential
    )

    #if forest is not specified, get current context forest
    If (!$ForestName)     
    {
        $ForestName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Name.ToString()    
    }        

    If ($Credential)     
    {        
        $credentialUser = $Credential.UserName.ToString()
        $credentialPassword = $Credential.GetNetworkCredential().Password.ToString()
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName, $credentialUser, $credentialPassword )
    }    
    Else     
    {        
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName)    
    }        

    $output = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx))    

    Return $output
}