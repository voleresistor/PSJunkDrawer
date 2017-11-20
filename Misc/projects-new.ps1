New-PSDrive -Name "DFSProjects" -PSProvider FileSystem -Root \\dxpe.com\Data\Projects

# Begin log
Start-Transcript -Path C:\DFSBackups\Logs\DFSProjects.log -Append

#Get a listing of the project folders
$a = Get-ChildItem DFSProjects:\ -Attributes Directory+!Hidden

# Check expiration of projects
foreach($x in $a){
    #Get project expiration days
    If(Import-CSV DFSProjects:\Configs\Projects.csv | Where-Object {$_.Project -eq $x.Name})
        {$b = (Import-CSV DFSProjects:\Configs\Projects.csv | Where-Object {$_.project -eq $x}).age}
    # Or set to a default length if it's not in the CSV
    Else
        {$b = 365}

    # Figure out how long the project has existed
    $y = ((Get-Date) - $x.CreationTime).Days

    # Compare age to expiration age, remove folder and CSV entry if expired
    if ($y -gt $b -and $x.PsISContainer -eq $True){
        echo "Removing item $x which is $y days old, with a scheduled expiration of $b days."
        Remove-Item -Recurse -Force DFSProjects:\$x
        Import-CSV DFSProjects:\Configs\Projects.csv | ? {$_.project -ne $x.Name} | Export-CSV DFSProjects:\Configs\Projects-Temp.csv
        Move-Item -Force -Path DFSProjects:\Configs\Projects-Temp.csv -Destination DFSProjects:\Configs\Projects.csv
    }
    Else{
        echo "Keeping item $x which is $y days old, with a scheduled expiration of $b days."
    }
            
}

# End log
Stop-Transcript

Remove-PSDrive -Name "DFSProjects" -Force