param(
    [string]$OutFile, #Path and name of output file. This file should end with the .csv extension. Defaults to current directory
    [switch]$MoveToStale, #Moves computers listed to the stale OU
    [string]$StaleDays = "90", #Number of days since last logon to consider stale. Default is 90 if unspecified
    [switch]$allData #Gather all properties of computers that meet $staleDays and export to $OutFile

)

#=============================
# Variables
#=============================

$expirDate = (Get-Date).AddDays(-($StaleDays))
if(!$OutFile){
    $OutFile = "\\dxpe.com\Data\Departments\IT\SysOps\StaleComputers\$(Get-Date -UFormat %d-%m-%Y)_StaleComputers.csv"
}

#=============================
# Functions
#=============================

Function logWrite ($message) {
    #$time = (Get-Date -uFormat %T)
    Add-Content -Path $OutFile -Value "$message"
}

#=============================
# Process
#=============================

try{
    if ($allData){
        Clear-Host
        Write-Host "`r`nWriting all properties to $OutFile..."
        $allList = Get-ADComputer -Filter "LastLogonDate -lt '$expirDate' -and OperatingSystem -like '*Windows*'" -SearchBase "OU=Workstations,DC=dxpe,DC=corp" -SearchScope OneLevel -Properties * -ErrorAction Stop
        $allList | Export-Csv -Path $OutFile

        Write-Host "`r`nDone with no errors!`r`n"
        exit 0
    }
    
    logWrite "Name,Operating System,Last Logon Date"
    Clear-Host
    Write-Host "`r`nGetting stale computers from AD...`r`n"

    $staleList = Get-ADComputer -Filter "LastLogonDate -lt '$expirDate' -and OperatingSystem -like '*Windows*'" -SearchBase "OU=Workstations,DC=dxpe,DC=corp" -SearchScope OneLevel -Properties Name,OperatingSystem,LastLogonDate -ErrorAction Stop
    $staleList | Format-Table -AutoSize -Property Name,Operatingsystem,LastLogonDate

    foreach ($c in $staleList){
        logWrite "$($c.Name),$($c.OperatingSystem),$($c.LastLogonDate)"

        if ($MoveToStale){
            #do scary things
            Move-ADObject -Identity $($c.ObjectGUID) -TargetPath "OU=Stale,OU=Workstations,DN=dxpe,DN=corp" -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Found $($staleList.Count) stale Windows workstations.`r`n"
    exit 0
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "A terminating error has ocurred!"
    Write-Host "The error message was: $ErrorMessage"
    exit 1
}

