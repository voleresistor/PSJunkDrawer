function Set-AclWithInheritance
{
    <#
    .Synopsis
    Update NTFS permissions in folders using .NET constructs.
    
    .Description
    Updates permissions. Sets inheritance on updated permission which triggers silent propagation throughout a folder structure.
    
    .Parameter Path
    The folder or file to change permissions on.

    .Parameter UserName
    The domain and username of the account or group to add to the ACL.

    .Parameter Rights
    The rights granted or disallowed for the account or group.

    .Parameter Inheritance
    How the new ACL is inherited by child objects.
    
    .Parameter AclType
    Allow or Deny.

    .Example
    Set-AclWithInheritance -Path C:\temp -UserName test\Administrators -Rights FullControl -Inheritance All -AclType Allow
    
    Equivalent to:
    icacls C:\temp /grant "test\Administrators":(OI)(CI)F

    .Notes
    ╔═════════════╦═════════════╦═══════════════════════════════╦════════════════════════╦══════════════════╦═══════════════════════╦═════════════╦═════════════╗
    ║             ║ folder only ║ folder, sub-folders and files ║ folder and sub-folders ║ folder and files ║ sub-folders and files ║ sub-folders ║    files    ║
    ╠═════════════╬═════════════╬═══════════════════════════════╬════════════════════════╬══════════════════╬═══════════════════════╬═════════════╬═════════════╣
    ║ Propagation ║ none        ║ none                          ║ none                   ║ none             ║ InheritOnly           ║ InheritOnly ║ InheritOnly ║
    ║ Inheritance ║ none        ║ Container|Object              ║ Container              ║ Object           ║ Container|Object      ║ Container   ║ Object      ║
    ╚═════════════╩═════════════╩═══════════════════════════════╩════════════════════════╩══════════════════╩═══════════════════════╩═════════════╩═════════════╝
    #>
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$UserName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Modify", "FullControl", "ReadWrite", "ReadOnly")]
        [string]$Rights,

        [Parameter(Mandatory=$true)]
        [ValidateSet("All", "ThisFolder", "FolderAndSub")]
        [string]$Inheritance,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Allow", "Deny")]
        [string]$AclType
    )

    # A pair of dictionaries to aid in translating user friendly strings to .NET friendly strings
    $rightsDict = @{
        "Modify" = "Modify";
        "FullControl" = "FullControl";
        "ReadWrite" = "Read, Write";
        "ReadOnly" = "ReadAndExecute"
    }

    $inheritanceDict = @{
        "All" = @("ContainerInherit", "ObjectInherit");
        "ThisFolder" = @("None");
        "FolderAndSub" = @("ContainerInherit")
    }

    # Build objects for the ACE
    $colRights = [System.Security.AccessControl.FileSystemRights]$rightsDict[$Rights]
    
    if (($inheritanceDict[$Inheritance]).Count -eq 1)
    {
        $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::($inheritanceDict[$Inheritance])
    }
    elseif (($inheritanceDict[$Inheritance]).Count -eq 2)
    {
        $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags] `
            ([System.Security.AccessControl.InheritanceFlags]::($inheritanceDict[$Inheritance][0]) -bor `
            [System.Security.AccessControl.InheritanceFlags]::($inheritanceDict[$Inheritance][1]))
    }
    else
    {
        Write-Error "Invalid count of Inheritance objects"
        return 1
    }
    
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
    $objType =[System.Security.AccessControl.AccessControlType]::$AclType
    $objUser = New-Object System.Security.Principal.NTAccount($UserName)

    # Build the ACE
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)

    #$MyStuff = @()
    #$MyStuff += $colRights
    #$MyStuff += $InheritanceFlag
    #$MyStuff += $PropagationFlag
    #$MyStuff += $objType
    #$MyStuff += $objUser
    #$MyStuff += $objACE
    #return $MyStuff

    # Get the existing ACL and add the new one to it
    $objACL = Get-ACL -Path $Path
    $objACL.AddAccessRule($objACE)

    # Apply the updated ACL
    Set-ACL -Path $Path -AclObject $objACL
}