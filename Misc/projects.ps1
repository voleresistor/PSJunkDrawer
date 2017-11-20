<# Projects.ps1
    Manage projects folders at Q:\Projects
    Checks age of existing folders against a CSV file and deletes if CSV age is exceeded

    CSV Format:
    Project, Age
    <project folder name>, <expiration age in days>

#>

New-PSDrive -Name "DFSProjects" -PSProvider FileSystem -Root \\dxpe.com\Data\Projects
#New-PSDrive -Name "DFSProjects" -PSProvider FileSystem -Root \\hou-cf-02\homedir\aogden\testdev

# Begin log - Deprecated for logWrite function
# Start-Transcript -Path C:\DFSBackups\Logs\DFSProjects.log -Append

# Define function for writing logs
Function logWrite ($message) {
    $time = (Get-Date -uFormat %T)
    Add-Content -Path "C:\DFSBackups\Logs\DFSProjects.log" -Value "[$time]$message"
    #Add-Content -Path "\\hou-cf-02\homedir\aogden\DFSProjects.log" -Value "[$time]$message"
}

# Begin logging
logWrite "********************"
logWrite "Begin daily DFSProjects check."

#Get a listing of the project folders
$DFSProjects = Get-ChildItem DFSProjects:\ -Attributes Directory+!Hidden
if (!$DFSProjects){
    logWrite "Unable to get directories in DFSPRojects. Exiting"
    exit 721077
}else{
    logWrite "Got $($DFSProjects.Length) items from DFSProjects."
}

# Check expiration of projects
foreach($folder in $DFSProjects){
    #Get project expiration days
    $projectSearch = (Import-CSV DFSProjects:\Configs\Projects.csv | Where-Object {$_.Project -eq $folder})
    If($projectSearch){
        $expirAge = $projectSearch.Age
        logWrite "Found item matching $folder in projects.csv. Setting expiration age to $expirAge."
    }else{ # Or set to a default length if it's not in the CSV
        logWrite "Couldn't find $folder in projects.csv or couldn't find projects.csv. Using default age of 365 days."
        $expirAge = 365
    }

    $originalCSV = (Import-Csv DFSProjects:\Configs\Projects.csv)

    # Figure out how long the project has existed
    $folderAge = ((Get-Date) - $folder.CreationTime).Days
    #logWrite "Folder is $folderAge days old."

    # Compare age to expiration age, remove folder and CSV entry if expired
    if ($folderAge -gt $expirAge -and $folder.PsISContainer -eq $True){
        logWrite "Removing item $folder which is $folderAge days old, with a scheduled expiration of $expirAge days."
        Remove-Item -Recurse -Force DFSProjects:\$folder
        if ((Test-Path -Path DFSProjects:\$folder) -eq $False){
            $originalCSV | ? {$_.project -ne $folder.Name} | Export-CSV DFSProjects:\Configs\Projects-Temp.csv -NoTypeInformation
            Move-Item -Force -Path DFSProjects:\Configs\Projects-Temp.csv -Destination DFSProjects:\Configs\Projects.csv
            logWrite "DFSProjects:\$folder successfully removed."
        }else{
            logwrite "Couldn't delete DFSProjects:\$folder."
        }
    }else{
        logWrite "Keeping item $folder which is $folderAge days old, with a scheduled expiration of $expirAge days."
    }
            
}

logWrite "Project scanning completed."

# End log - Deprecated with begin log
# Stop-Transcript

Remove-PSDrive -Name "DFSProjects" -Force