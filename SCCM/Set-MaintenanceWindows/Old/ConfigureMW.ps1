Clear-Host

# Import ConfigMgr PSH Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$MWBaseName = "SUP-"

# Get the CMSITE SiteCode
$SiteCode = Get-PSDrive -PSProvider CMSITE
$FileEntries = Get-Content G:\Scripts\PowerShell\ConfigureMW\MWInputPredeploy.txt | Select-Object -Skip 1
foreach ($FileEntry in $FileEntries) {
    $fields = $FileEntry -split ','
    $MWStart = $fields[0] + " 01:00"
    $MWEnd = $fields[0] + " 05:00"
    $MWTarget = $fields[1]
    
    #Use the DataTime.Parse() Method to parse in date to a DateTime 
    $StartTime = [DateTime]::Parse($MWStart) 
    $EndTime = [DateTime]::Parse($MWEnd) 
 
    $MWName = $MWBaseName + (get-date ($fields[0]) -UFormat "%B %d")
    # Change the connection context
    Set-Location "$($SiteCode.Name):\"

    #Create The ScheduleToken 
    $Schedule = New-CMSchedule -NonRecurring -Start $StartTime -End $EndTime
    Write-Host "Setting MW: '$($MWName)' on $($MWTarget) &gt; $($MWStart) - $($MWEnd)"
    
    New-CMMaintenanceWindow -ApplyToSoftwareUpdateOnly -CollectionID $MWTarget -Schedule $Schedule -Name $MWName | Out-Null
}