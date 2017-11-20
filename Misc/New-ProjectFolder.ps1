<# New-ProjectFolder.ps1
    DESCRIPTION: Use to create new project folders, set permissions,
                set owners, and create csv entries as well as email
                project owners.
    CREATOR: Andrew Ogden
    Date: 31/01/2014
#>

Param (
    [Parameter(Mandatory=$True)][string]$FolderName,
    [Parameter(Mandatory=$True)][string]$Owner,
    [array]$ExtraEmails,
    [Parameter(Mandatory=$True)]$ExpirDays,
    [array]$ReadUsers,
    [array]$WriteUsers,
    [switch]$help
)

# Display help if requested
if ( $help -eq $true ){
    Write-Host "-FolderName: " -NoNewline -ForegroundColor Green
    Write-Host "What should the folder name be?"
    Write-Host "-Owner: " -NoNewline -ForegroundColor Green
    Write-Host "Who should be the owner of the project folder? Use form <user>@dxpe.corp"
    Write-Host "-ExtraEmails: " -NoNewline -ForegroundColor Green
    Write-Host "Anyone besides the folder owner who needs to recieve a notification."
    Write-Host "-ExpirDays: " -NoNewline -ForegroundColor Green
    Write-Host "Number of days til project expiration."
    Write-Host "-Users: " -NoNewline -ForegroundColor Green
    Write-Host "List of users who should have access to the folder in this form: `"User1`",`"User2`",`"User3`""
    Write-Host "-help: " -NoNewline -ForegroundColor Green
    Write-Host "Show this help message."
    exit
}

try {
    # Mount Projects root
    #New-PSDrive -Name Projects -PSProvider FileSystem -Root \\dxpe.com\data\Projects\ -ErrorAction Stop >$null
    New-PSDrive -Name Projects -PSProvider FileSystem -Root X:\test -ErrorAction Stop >$null

    # Create new folder
    New-Item -Path Projects:\ -Name $FolderName -ItemType directory -ErrorAction Stop
    
    # Add project owner to WriteUsers
    $WriteUsers += $Owner

    # Add WriteUsers permissions to folder
    foreach ($u in $WriteUsers){
        $acl = (Get-ACL Projects:\$FolderName -ErrorAction Stop)
        $Right = [System.Security.AccessControl.FileSystemRights]"Read, Write, ReadAndExecute" 
        $InheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
        $objType =[System.Security.AccessControl.AccessControlType]::Allow        
        $objUser = New-Object System.Security.Principal.NTAccount($u) 
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $Right, $InheritanceFlag, $PropagationFlag, $objType) 
        $acl.AddAccessRule($objACE)
        Set-ACL Projects:\$FolderName -AclObject $acl -ErrorAction Continue
    }

    # Add ReadUsers permissions to folder
    foreach ($u in $ReadUsers){
        $acl = (Get-ACL Projects:\$FolderName -ErrorAction Stop)
        $Right = [System.Security.AccessControl.FileSystemRights]"Read, ReadAndExecute" 
        $InheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
        $objType =[System.Security.AccessControl.AccessControlType]::Allow        
        $objUser = New-Object System.Security.Principal.NTAccount($u) 
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $Right, $InheritanceFlag, $PropagationFlag, $objType) 
        $acl.AddAccessRule($objACE)
        Set-ACL Projects:\$FolderName -AclObject $acl -ErrorAction Continue
    }

    # Set project owner as folder owner
    $acl = (Get-ACL Projects:\$FolderName -ErrorAction Stop)
    $acl.SetOwner([System.Security.Principal.NTAccount]$Owner)
    Set-ACL Projects:\$FolderName -AclObject $acl -ErrorAction Continue

    # Add entry to project CSV
    $projectEntry = "$FolderName,$ExpirDays"
    Out-File -FilePath \\dxpe.com\data\Projects\Configs\Projects.csv -InputObject $projectEntry -Append -Encoding ASCII -ErrorAction Continue
    Out-File -FilePath x:\test\Projects.csv -InputObject $projectEntry -Append -Encoding ASCII -ErrorAction Continue

    # Send email notifying target user
    $currentDate = Get-Date -Hour 2 -Minute 0 -Second 0
    $futureDate = $currentDate.AddDays($expirDays+1)
    #$deleteDate = $futureDate.AddDays(1)
    $message =
@"

This project folder has been created and can be accessed at \\dxpe.com\data\Projects\$FolderName

It is set to expire in $ExpirDays days. Expiration will result in automatic deletion on $futureDate AM. If you need to extend this project, contact me before this time.

Please let me know if you have any issues with this share.

"@
        
    $emailFrom = "aogden@dxpe.com"
    $emailTo = "$Owner, $extraEmails"
    $subject="$FolderName project folder"
    $smtpserver="smtp.dxpe.com"
    $smtp=New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($emailFrom, $emailTo, $subject, $message)
}

catch {
    Write-Host "`nError: " -ForegroundColor Red -NoNewline
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}

finally {
    Remove-PSDrive -Name Projects -Force
}