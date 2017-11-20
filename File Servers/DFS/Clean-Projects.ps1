<# Projects.ps1
    Manage projects folders at Q:\Projects
    Checks age of existing folders against a CSV file and deletes if CSV age is exceeded

    CSV Format:
    ProjectName,ExpirDate,Contact
    <project folder name>,<expiration date>,<contact email>

#>

# Define administrative contact
$adminEmail = "aogden@dxpe.com"

# Create PS drive to access projects
#New-PSDrive -Name "DFSProjects" -PSProvider FileSystem -Root \\dxpe.com\Data\Projects
New-PSDrive -Name "DFSProjects" -PSProvider FileSystem -Root C:\Temp\test


# Define function for writing logs
Function logWrite ($message) {
    $time = (Get-Date -uFormat %T)
    #Add-Content -Path "C:\DFSBackups\Logs\DFSProjects.log" -Value "[$time]$message"
    Add-Content -Path "C:\temp\projectlogs\DFSProjects.log" -Value "[$time]$message"
}

Function sendEmail (
    [string]$mailTo,
    [string]$mailType
){
    switch ($mailType){
        "deleteFailed" {
            $mailMessage = "The deletion of $($folder.Name) from \\dxpe.com\Data\Projects failed."
            $mailSubject = "Delete failed"
            $Priority = "High"
        }
        "noProjectEntry" {
            $mailMessage = "No entry could be found in the CSV file for $($folder.Name)."
            $mailSubject = "No CSV entry for project"
            $Priority = "High"
        }
        "removedProject" {
            $mailMessage = "The project folder $($folder.Name) expired on $($projectSearch.ExpirDate) and was removed from \\dxpe.com\Data\Projects.<br><br>Please contact Andrew Ogden at <a href=`"mailto:aogden@dxpe.com`">aogden@dxpe.com</a> if this project was deleted in error.<br><br>If you are done with this folder and no longer need the data contained within it, no further action is required."
            $mailSubject = "$($folder.Name) Project folder deleted"
            $Priority = "Normal"
        }
        "threeDayExpir" {
            $mailMessage = "The project folder $($folder.Name) will be expiring in three days. At this time, the folder and all data will be automatically deleted.<br><br>Please contact Andrew Ogden at <a href=`"mailto:aogden@dxpe.com`">aogden@dxpe.com</a> if you need to extend this project.<br><br>If you are done with this folder and no longer need the data contained within it, no further action is required."
            $mailSubject = "$($folder.Name) Project folder expiration"
            $Priority = "Normal"
        }
        "sevenDayExpir" {
            $mailMessage = "The project folder $($folder.Name) will be expiring in seven days. At this time, the folder and all data will be automatically deleted.<br><br>Please contact Andrew Ogden at <a href=`"mailto:aogden@dxpe.com`">aogden@dxpe.com</a> if you need to extend this project.<br><br>If you are done with this folder and no longer need the data contained within it, no further action is required."
            $mailSubject = "$($folder.Name) Project folder expiration"
            $Priority = "Normal"
        }
        default {
            logWrite "Bad mailType specified, no email sent."
            exit 721077
        }
    }


    $mailFrom = "DXPE Projects<DXPEProjects@dxpe.com>"
    $SmtpServer = "smtp.dxpe.com"
    Send-MailMessage -To $MailTo -From $MailFrom -Subject $mailSubject -Body $mailMessage -SmtpServer $SmtpServer -Priority $Priority -BodyAsHtml
}

# Begin logging
logWrite "********************"
logWrite "Begin daily DFSProjects check."

#Get a listing of the project folders
$DFSProjects = Get-ChildItem DFSProjects:\ -Attributes Directory+!Hidden
if (!$DFSProjects){
    logWrite "No projects or unable to check project folders."
    exit 721077
}else{
    logWrite "Found $($DFSProjects.Length) project folders."
}

# Copy csv data into a variable so we don't have to open the file for every loop iteration
if (Test-Path -Path DFSProjects:\Configs\Projects.csv){
    $ProjectCsv = Import-Csv DFSProjects:\Configs\Projects.csv
    logWrite "Found $($ProjectCsv.Length) project entries."
} else {
    logWrite "Projects.csv not found."
    exit 721077
}

# Check expiration of projects
foreach($folder in $DFSProjects){

    #Get project information
    $projectSearch = ($ProjectCsv | Where-Object { $_.ProjectName -eq $($folder.Name) })

    If($projectSearch){
        $expirDays = ([datetime]$($projectSearch.ExpirDate) - (Get-Date))
        logWrite "Found item matching $folder in projects.csv. $($folder.Name) expires in $($expirDays.Days) days ($($projectSearch.ExpirDate))."
    }else{
        # Or set to a default length if it's not in the CSV
        logWrite "Couldn't find $($folder.Name) in projects.csv. Using default age of 365 days and notifying the administrator."
        $expirDays = ((Get-Date).AddDays(365) - (Get-Date))
        sendEmail -mailTo $adminEmail -mailType noProjectEntry
    }

    # Compare age to expiration age, move folder and CSV entry if expired
    if ($($expirDays.Days) -lt 0 -and $($folder.PsISContainer) -eq $True){
        # Move project to archive
        logWrite "Removing item $($folder.Name) which expired on $($projectSearch.ExpirDate)"
        Move-Item -Path DFSProjects:\$($folder.Name) -Destination DFSProjects:\Archive\$($folder.Name) -Force

        if ((Test-Path -Path DFSProjects:\$($folder.Name)) -eq $False){
            # Remove CSV entry
            $ProjectCsv | Where-Object { $_.ProjectName -ne $folder.Name } | Export-CSV DFSProjects:\Configs\Projects-Temp.csv -NoTypeInformation
            Move-Item -Force -Path DFSProjects:\Configs\Projects-Temp.csv -Destination DFSProjects:\Configs\Projects.csv
            $ProjectCsv = Import-Csv DFSProjects:\Configs\Projects.csv
            logWrite "DFSProjects:\$($folder.Name) successfully removed."

            # Email admin and contact to inform them of completed deletion
            sendEmail -mailTo $adminEmail -mailType removedProject
            sendEmail -mailTo $($projectSearch.Contact) -mailType removedProject
        } else {
            logwrite "Couldn't delete DFSProjects:\$($folder.Name)."
            sendEmail -mailTo $adminEmail -mailType deleteFailed
        }
    } elseif ($($expirDays.Days) -eq 3){
        logWrite "Project $($folder.Name) expires in three days."
        sendEmail -mailTo $adminEmail -mailType threeDayExpir
        sendEmail -mailTo $($projectSearch.Contact) -mailType threeDayExpir
    } elseif ($($expirDays.Days) -eq 7){
        logWrite "Project $($folder.Name) expires in seven days."
        sendEmail -mailTo $adminEmail -mailType sevenDayExpir
        sendEmail -mailTo $($projectSearch.Contact) -mailType sevenDayExpir
    }
            
}

logWrite "Project scanning completed."

Remove-PSDrive -Name "DFSProjects" -Force