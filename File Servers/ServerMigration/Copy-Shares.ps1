param
(
    [Parameter(Mandatory=$true)]
    [string]$InputCsv,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\temp\Copy-Netapp"
)

# Initialize log path
if (!(Test-Path -Path $LogPath))
{
    New-Item -Path $LogPath -Force -ItemType Directory | Out-Null
}

#Import CSV file
$CsvFile = Import-Csv -Path $InputCsv -Delimiter ','

foreach ($entry in $CsvFile)
{
    #region ToBeRemoved
    <#
    Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Source share: $($entry.OldPath)" -Path $LogFile
    #Open PSRemote session to TargetServer and ReplServer
    try
    {
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Connecting to $($entry.TargetServer) and $($entry.ReplServer)" -Path $LogFile
        $TargetSess = New-PSSession -ComputerName $($entry.TargetServer) -Name 'TargetServer'
        $ReplSess = New-PSSession -ComputerName $($entry.ReplServer) -Name 'ReplServer'
    }
    catch
    {
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Failed opening a remote session." -Path $LogFile
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> $($_.Exception.Message)" -Path $LogFile
        continue
    }

    #Get source ACL object from source folder
    Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Getting existing ACL from $($entry.OldPath)" -Path $LogFile
    $SourceAcl = Get-Acl -Path $($entry.OldPath)
    $Domain,$UName = $SourceAcl.Owner -split ('\\')

    #Gather only unique ACEs from $SourceAcl
    $SourceAces = @()
    foreach ($ace in $SourceAcl.Access)
    {
        if ($ace.IdentityReference -notlike "*Domain Admins" -and $ace.IdentityReference -notlike "*HelpDesk")
        {
            $SourceAces += $ace
        }
    }

    #Create new folder on TargetServer and ReplServer
    Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Creating folder on $($entry.TargetServer)" -Path $LogFile
    $TargetFolder = Invoke-Command -Session $TargetSess -ArgumentList $($entry.TargetDrive),$($entry.FolderName) `
        -ScriptBlock { New-Item -Path "$($args[0]):\" -Name $($args[1]) -ItemType Directory }

    Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Creating folder on $($entry.ReplServer)" -Path $LogFile
    $ReplFolder = Invoke-Command -Session $ReplSess -ArgumentList $($entry.ReplDrive),$($entry.FolderName) `
        -ScriptBlock { New-Item -Path "$($args[0]):\" -Name $($args[1]) -ItemType Directory }
    
    if (!$TargetFolder -or !$ReplFolder)
    {
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Failed creating a folder." -Path $LogFile
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> $(($error | Select-Object -first 1).ToString())" -Path $LogFile
        continue
    }

    #Apply source ACL to folder on TargetServer and ReplServer
    $TargetAdmin = '\\' + $entry.TargetServer + '\' + $entry.TargetDrive + '$\' + $entry.FolderName
    $ReplAdmin = '\\' + $entry.ReplServer + '\' + $entry.ReplDrive + '$\' + $entry.FolderName
    $domain,$uname = $SourceAcl.Owner -split ('\\')

    $tAcl = Get-Acl -Path $TargetAdmin
    $rAcl = Get-Acl -Path $ReplAdmin
    $owner = New-Object System.Security.Principal.NTAccount($domain, $uname) | Out-Null

    # Set owner
    if ($owner)
    {
        $tAcl.SetOwner($owner)
        $rAcl.SetOwner($owner)
    }

    # Apply ACL
    foreach ($ace in $SourceAces)
    {
        $newAcl = New-Object System.Security.AccessControl.FileSystemAccessRule($ace.IdentityReference, `
            $ace.FileSystemRights, `
            $ace.InheritanceFlags, `
            $ace.PropagationFlags, `
            $ace.AccessControlType)
        $tAcl.AddAccessRule($newAcl)
        $rAcl.AddAccessRule($newAcl)
    }

    #Apply modified ACLs
    try
    {
        Set-Acl -Path $TargetAdmin -AclObject $tAcl
        Set-Acl -Path $ReplAdmin -AclObject $rAcl
    }
    catch
    {
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> Failed setting ACL" -Path $LogFile
        Add-Content -Value "$(Get-date -UFormat '%m/%d/%Y - %H:%M:%S')> $($_.Exception.Message)" -Path $LogFile
        continue
    }#>
    #endregion

    Start-Process -FilePath "$env:windir\System32\robocopy.exe" -ArgumentList "`"$($entry.SourcePath)`" `"$($entry.DestPath)`" /E /XO /COPY:DATSO /DCOPY:DAT /LOG+:`"$LogPath\$($entry.ShareName).log`"" -Wait -NoNewWindow
}