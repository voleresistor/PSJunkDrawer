param
(
    [Parameter(Mandatory=$true)]
    [string]$InputCsv,

    [Parameter(Mandatory=$false)]
    [switch]$CreateShare,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\temp\Copy-NetApp\New-ShareFolder.log"
)

<#
    .Synopsis
    Creates new folders and shares.
    
    .Description
    Using a list of source shares and destination servers, creates folders and shares and copies ownership and ACLs to the new folders.
    
    .Parameter InputCsv
    The CSV file containing settings for this script.

    .Parameter CreateShare
    Creates and SMB file share on each server corresponding to the folder.

    .Parameter LogPath
    The location and name of the logfile.
    
    .Example
    New-ShareFolders.ps1 -InputCsv c:\temp\migration.csv -CreateShare
    
    Creates folders and shares for each source/primary server/replication server entry in the input CSV.
#>

# Include useful functions
. .\Include\UsefulFunctions.ps1

# Initialize log
Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message ' '
Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Begin New-ShareFolders"

# Set up list of ACEs to ignore
$IgnoreACEs = @('DXPE\Domain Admins', 'DXPE\HelpDesk', 'DXPECOM\HelpDesk', 'DXPECOM\Domain Admins',
    'CREATOR OWNER', 'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'DXPECOM\FileServerAdministration',
    'DXPE\IT HelpDesk') # 'NT AUTHORITY\Authenticated Users',
Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Ignore ACEs: $ignoreACEs"

#Import CSV file
$CsvFile = Import-Csv -Path $InputCsv -Delimiter ','

foreach ($entry in $CsvFile)
{
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message ' '
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Source: $($entry.SourcePath)"

    # Get source folder ACL and owner
    $SourceAcl = Get-Acl -Path $($entry.SourcePath)
    $Domain,$UName = $SourceAcl.Owner -split ('\\')

    #Gather only unique ACEs from $SourceAcl
    $SourceAces = @()
    foreach ($ace in $SourceAcl.Access)
    {
        if (!(($IgnoreACEs -contains ($ace.IdentityReference)) -or ($ace.IdentityReference -match "S-\d-\d-[\d]{2}-[\d]{10}-[\d]{10}-[\d]{9}-[\d]{5}")))
        {
            Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Adding $($ace.IdentityReference) with type $($ace.AccessControlType) for $($ace.FileSystemRights) to source ACEs"
            $SourceAces += $ace
        }
    }

    # Create primary and replication folders
    $primaryPath = "\\" + $($entry.PrimaryServer) + "\" + $($entry.PrimaryDrive) + "$\" + $($entry.ParentFolder)
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Primary Path: $primaryPath"
    $replPath = "\\" + $($entry.ReplServer) + "\" + $($entry.ReplDrive) + "$\" + $($entry.ParentFolder)
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Repl Path: $replPath"

    if (!(Test-Path "$primaryPath\$($entry.ShareName)"))
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Creating folder $($entry.ShareName) on $primaryPath"
        New-Item -Path $primaryPath -Name $($entry.ShareName) -ItemType Directory
    }
    else
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "$primaryPath\$($entry.ShareName) already exists. Skipping this share." -Type 'Warning'
        continue
    }

    if (!(Test-Path "$replPath\$($entry.ShareName)"))
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Creating folder $($entry.ShareName) on $replPath"
        New-Item -Path $replPath -Name $($entry.ShareName) -ItemType Directory
    }
    else
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "$replPath\$($entry.ShareName) already exists. Skipping this share." -Type 'Warning'
        continue
    }

    # Get owner of source share
    $domain,$uname = $SourceAcl.Owner -split ('\\')
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Source owner domain: $domain"
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Source owner username: $uname"

    # Get current ACL from primary folder
    $primaryAcl = Get-Acl -Path $($primaryPath + "\" + $($entry.ShareName))

    # Create owner object
    $owner = New-Object System.Security.Principal.NTAccount($domain, $uname)# | Out-Null (Derp)

    # Set owner
    if ($owner)
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Setting owner $($owner.Value) on $($primaryPath + "\" + $($entry.ShareName))"
        $primaryAcl.SetOwner($owner)
    }
    else
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Unable to create owner object. Share owner will remain BUILTIN\Administrators" -Type 'Warning'
    }

    # Apply ACL
    foreach ($ace in $SourceAces)
    {
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Adding $($ace.IdentityReference) with type $($ace.AccessControlType) for $($ace.FileSystemRights) to new ACL object"
        $newAcl = New-Object System.Security.AccessControl.FileSystemAccessRule($ace.IdentityReference, `
            $ace.FileSystemRights, `
            $ace.InheritanceFlags, `
            $ace.PropagationFlags, `
            $ace.AccessControlType)
        $primaryAcl.AddAccessRule($newAcl)
    }

    #Apply modified ACLs
    Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Applying new ACL to $($primaryPath + "\" + $($entry.ShareName))"
    Set-Acl -Path $($primaryPath + "\" + $($entry.ShareName)) -AclObject $primaryAcl

    # Create shares
    if ($CreateShare)
    {
        # Share creation script block
        $newShare = {
            if (!(Get-SmbShare -Name $args[0]))
            {
                New-SmbShare -FullAccess Everyone -Name $args[0] -Path $args[1] -Description $args[2]
                return $true
            }
            else
            {
                return $false
            }
        }

        # Create primary share
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Creating new share: \\$($entry.PrimaryServer)\$($entry.ShareName)"
        $SharePath = $($entry.PrimaryDrive) + ":\" + $($entry.ParentFolder) + "\" + $($entry.ShareName)
        $result = Invoke-Command -ComputerName $($entry.PrimaryServer) -ScriptBlock $newShare -ArgumentList $($entry.ShareName),$SharePath,$($entry.ShareDescription)
        if ($result -eq $true)
        {
            Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Created share: \\$($entry.PrimaryServer)\$($entry.ShareName)"
        }
        else
        {
            Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Error creating share: \\$($entry.PrimaryServer)\$($entry.ShareName)" -Type 'Error'
            continue
        }

        # Create replication share
        Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Creating new share: \\$($entry.ReplServer)\$($entry.ShareName)"
        $SharePath = $($entry.ReplDrive) + ":\" + $($entry.ParentFolder) + "\" + $($entry.ShareName)
        $result = Invoke-Command -ComputerName $($entry.ReplServer) -ScriptBlock $newShare -ArgumentList $($entry.ShareName),$SharePath,$($entry.ShareDescription)
        if ($result -eq $true)
        {
            Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Created share: \\$($entry.ReplServer)\$($entry.ShareName)"
        }
        else
        {
            Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Error creating share: \\$($entry.ReplServer)\$($entry.ShareName)" -Type 'Error'
            continue
        }
    }

    Clear-Variable -Name owner,newacl,primaryacl
}

Write-Log -LogPath $LogPath -Component 'New-ShareFolders' -File 'New-ShareFolders.ps1' -Message "Done."