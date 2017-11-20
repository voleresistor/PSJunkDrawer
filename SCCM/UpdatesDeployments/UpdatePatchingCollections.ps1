# David Lassen
# Get servers, Patch Tiers from \\hou-cf-02\Departments\IT\Repository\SysOps\DXP Server Information.xlsx
# Add to Server Tier Collections

Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE
$erroractionpreference = "SilentlyContinue"
$LogPath = "$env:temp\UpdatePatchingCollections.log"

#### Functions

Function LogWrite
{
   Param ([string]$logstring)
   $time = (Get-Date -uFormat %T)
   Add-Content -Path $LogPath -Value "[$time] >> $logstring"
}


function FindSheet([Object]$workbook, [string]$name)
{
     $sheetNumber = 0
    for ($i=1; $i -le $workbook.Sheets.Count; $i++) {

         if ($name -eq $workbook.Sheets.Item($i).Name) { $sheetNumber =  $i; break }
    }
    return $sheetNumber
}


Function CheckRemoveServerColl($ServerName,$CollName) 
{
    If ((Get-CMDeviceCollectionDirectMembershipRule -CollectionName $CollName -ResourceName $ServerName))
    {
         Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $CollName -ResourceName $ServerName -Force
         LogWrite "Deleted $ServerName in Patching collection $CollName"
    }
}



function SetActiveSheet([Object]$workbook, [string]$name)
{
    if (!$name) { return }
     $sheetNumber = FindSheet $workbook $name
    if ($sheetNumber -gt 0) { $workbook.Worksheets.Item($sheetNumber).Activate() }
    return ($sheetNumber -gt 0)
}

function Import-Excel([string]$FilePath, [string]$SheetName = "")
{
    $csvFile = Join-Path $env:temp ("{0}.csv" -f (Get-Item -path $FilePath).BaseName)
    if (Test-Path -path $csvFile) { Remove-Item -path  $csvFile }

    $xlCSVType = 6 # SEE: http://msdn.microsoft.com/en-us/library/bb241279.aspx
    $excelObject = New-Object -ComObject Excel.Application  
    $excelObject.Visible = $false 
    $workbookObject = $excelObject.Workbooks.Open($FilePath)
    SetActiveSheet $workbookObject $SheetName | Out-Null
    $workbookObject.SaveAs($csvFile,$xlCSVType)  
    $workbookObject.Saved = $true
    $workbookObject.Close()

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbookObject) | 
        Out-Null
        $excelObject.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObject) |
        Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    Return $csvFile

}

function ProcessCsv 
{
    Param ([string]$CSVFile)
    
    $cvsfile = Import-Csv -path $CSVFile
    
    ForEach ( $line in $cvsfile ) 
    {
    
        $ServerName = $line.Name
        $PatchTier = $line."Patch Tier"
    
        CD "$($SiteCode):"
        If ($PatchTier -ne "0" -Or $PatchTier -ne $Null) {$isActive = (Get-CMDevice -Name $ServerName).IsClient} 
       
        If ($isActive -eq "True") 
        {
            If ($PatchTier -eq "Pre-Deploy") 
            {
                If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $PreDeploy -ResourceName $ServerName)) 
                {
                    Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $PreDeploy -ResourceId $(get-cmdevice -Name $ServerName).ResourceID
                    LogWrite "Adding $ServerName ($((get-cmdevice -Name $ServerName).ResourceID)) to Patching collection $PreDeploy >> $PatchTier"
                }
                Else
                {
                    LogWrite "$ServerName already in Patching collection $PreDeploy"
                }
            
                CheckRemoveServerColl $ServerName $Coll1
                CheckRemoveServerColl $ServerName $Coll2A
                CheckRemoveServerColl $ServerName $Coll2B
                CheckRemoveServerColl $ServerName $Coll3    
            }
            ElseIf ($PatchTier -eq "1") 
            {
                If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Coll1 -ResourceName $ServerName)) 
                {
                    Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $Coll1 -ResourceId $(get-cmdevice -Name $ServerName).ResourceID
                    LogWrite "Adding $ServerName ($((get-cmdevice -Name $ServerName).ResourceID)) to Patching collection $Coll1 >> $PatchTier"
                }
                Else
                {
                    LogWrite "$ServerName already in Patching collection $Coll1"
                }
                
                CheckRemoveServerColl $ServerName $PreDeploy 
                CheckRemoveServerColl $ServerName $Coll2A
                CheckRemoveServerColl $ServerName $Coll2B
                CheckRemoveServerColl $ServerName $Coll3    
            }
            ElseIf ($PatchTier -eq "2A")
            {
                If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Coll2A -ResourceName $ServerName)) 
                {
                    Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $Coll2A -ResourceId $(get-cmdevice -Name $ServerName).ResourceID
                    LogWrite "Adding $ServerName ($((get-cmdevice -Name $ServerName).ResourceID)) to Patching collection $Coll2A >> $PatchTier"

                }
                Else
                {
                    LogWrite "$ServerName already in Patching collection $Coll2A"
                }
       
                CheckRemoveServerColl $ServerName $PreDeploy
                CheckRemoveServerColl $ServerName $Coll1
                CheckRemoveServerColl $ServerName $Coll2B
                CheckRemoveServerColl $ServerName $Coll3    
           }
            ElseIf ($PatchTier -eq "2B")
            {
               If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Coll2B -ResourceName $ServerName)) 
                {
                    Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $Coll2B -ResourceId $(get-cmdevice -Name $ServerName).ResourceID
                    LogWrite "Adding $ServerName ($((get-cmdevice -Name $ServerName).ResourceID)) to Patching collection $Coll2B >> $PatchTier"
                }
                Else
                {
                    LogWrite "$ServerName already in Patching collection $Coll2B"
                }

                CheckRemoveServerColl $ServerName $PreDeploy 
                CheckRemoveServerColl $ServerName $Coll1
                CheckRemoveServerColl $ServerName $Coll2A
                CheckRemoveServerColl $ServerName $Coll3    
            }
            Elseif ($PatchTier -eq "3") 
            {
               If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Coll3 -ResourceName $ServerName)) 
                {
                    Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $Coll3 -ResourceId $(get-cmdevice -Name $ServerName).ResourceID
                    LogWrite "Adding $ServerName ($((get-cmdevice -Name $ServerName).ResourceID)) to Patching collection $Coll3 >> $PatchTier"
                }
                Else
                {
                    LogWrite "$ServerName already in Patching collection $Coll3"
                }
                
                CheckRemoveServerColl $ServerName $PreDeploy
                CheckRemoveServerColl $ServerName $Coll1
                CheckRemoveServerColl $ServerName $Coll2A
                CheckRemoveServerColl $ServerName $Coll2B    
            }
        }
     }   

CD "C:"
}


# delete old log file if exist
if(Test-Path -Path $Logpath) {
    Remove-Item -Path $logPath -Force 
}

#Copy to work folder
cd "C:"
#$ServerInfo = "D:\Work\Patching\Test.xlsx"
$ServerInfoName = "DXP Server Information.xlsx"
$ServerInfo = "\\hou-cf-02\Departments\IT\Repository\SysOps\DXP Server Information.xlsx"

Copy-Item $ServerInfo $env:temp -Force
if(!(Test-Path -Path $env:temp\$ServerInfoName)) {
    WriteLog "File Not found $env:temp\$ServerInfoName"
    Exit
}

LogWrite "Copied $ServerInfoName to Temp..."
LogWrite "Processing ..."
LogWrite ""

$Coll1 = "Tier 1"
$Coll2A = "Tier 2A"
$Coll2B = "Tier 2B"
$Coll3 = "Tier 3"
$PreDeploy = "Pre-Deployment - Server Updates"

$csv = Import-Excel $ServerInfo "Houston"
ProcessCsv $csv
$csv = Import-Excel $ServerInfo "Citrix"
ProcessCsv $csv
$csv = Import-Excel $ServerInfo "Dev"
ProcessCsv $csv
$csv = Import-Excel $ServerInfo "Omaha"
ProcessCsv $csv
$csv = Import-Excel $ServerInfo "Natpro"
ProcessCsv $csv

LogWrite ""









