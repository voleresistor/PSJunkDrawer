<# 
********************************************************************************************************** 
*                                                                                                        * 
*** This Powershell Script is used to clean the CCM cache of all non persisted content                  ** 
*                                                                                                        * 
********************************************************************************************************** 
* Created by Ioan Popovici, 13/11/2015  | Requirements Powershell 3.0                                    * 
* =======================================================================================================* 
* Modified by   |    Date    | Revision |                            Comments                            * 
*________________________________________________________________________________________________________* 
* Ioan Popovici | 13/11/2015 | v1.0      | First version                                                 * 
* Ioan Popovici | 16/11/2015 | v1.1      | Improved Loging                                               * 
* Ioan Popovici | 16/11/2015 | v1.2      | Vastly Improved                                               * 
*--------------------------------------------------------------------------------------------------------* 
*                                                                                                        * 
********************************************************************************************************** 
 
    .SYNOPSIS 
        This Powershell Script is used to clean the CCM cache of all non persisted content. 
    .DESCRIPTION 
        This Powershell Script is used to clean the CCM cache of all non persisted content that is not needed anymore. 
        It only cleans packages, applications and updates that have a installed status and are not persisted, other  
        chache items will NOT be cleaned. 
#> 
 
##Initialization 
CLS 
 
#Global variable 
$Global:Result  =@()  
 
#Set log path 
$ResultCSV = "C:\Temp\Clean-CCMCache.log" 
 
#Remove previous log it it's more than 500 KB 
If (Test-Path $ResultCSV) { 
    If ((Get-Item $ResultCSV).Length -gt 500KB) { 
        Remove-Item $ResultCSV -Force | Out-Null 
    } 
} 
 
#Get log parent path 
$ResultPath =  Split-Path $ResultCSV -Parent 
 
#Create path directory if it does not exist 
If ((Test-Path $ResultPath) -eq $False) { 
    New-Item -Path $ResultPath -Type Directory | Out-Null 
} 
 
#Get the current date 
$Date = Get-Date 
 
#Get list of all non persisted content in CCMcache, only this content will be removed 
$CM_CacheItems = Get-WmiObject -Namespace root\ccm\SoftMgmtAgent -Query 'SELECT ContentID,Location FROM CacheInfoEx WHERE PersistInCache = 0' 
 
#Get list of updates 
$CM_Updates = Get-WmiObject -Namespace root\ccm\SoftwareUpdates\UpdatesStore -Query 'SELECT UniqueID,Title,Status FROM CCM_UpdateStatus' 
 
#Get list of applications 
$CM_Applications = Get-WmiObject -Namespace root\ccm\ClientSDK -Query 'SELECT * FROM CCM_Application' 
 
#Get list of packages 
$CM_Packages = Get-WmiObject -Namespace root\ccm\ClientSDK -Query 'SELECT PackageID,PackageName,LastRunStatus,RepeatRunBehavior FROM CCM_Program' 
 
##Functions 
 
#This function is used to remove the cache item pushed trough it if it's not persisted 
Function Remove-CacheItem { 
    param ( 
        [Parameter(Mandatory = $true, Position = 0)] 
        [Alias('CacheTD')] 
        [string]$CacheItemToDelete, 
        [Parameter(Mandatory = $true, Position = 0)] 
        [Alias('CacheN')] 
        [string]$CacheItemName 
    ) 
 
    #Delete chache item if it's non persisted 
    If ($CM_CacheItems.ContentID -contains $CacheItemToDelete) { 
 
        #Get Cache item location and size 
        $CacheItemLocation = $CM_CacheItems | Where {$_.ContentID -Contains $CacheItemToDelete} | Select -ExpandProperty Location 
        $CacheItemSize =  Get-ChildItem $CacheItemLocation -Recurse -Force | Measure-Object -Property Length -Sum | Select -ExpandProperty Sum 
 
        #Build result object 
        $ResultProps = [ordered]@{ 
            'DeletionDate'  = $Date 
            'Name' = $CacheItemName 
            'ID' = $CacheItemToDelete 
            'Location' = $CacheItemLocation 
            'Size(MB)' = "{0:N2}" -f ($CacheItemSize / 1MB) 
            'TotalDeleted(MB)' = '' 
        } 
 
        #Add items to result object 
        $Global:Result  += New-Object PSObject -Property $ResultProps 
 
        #Connect to resource manager COM object 
        $CMObject = New-Object -ComObject "UIResource.UIResourceMgr" 
 
        #Use GetCacheInfo method to return cache properties 
        $CMCacheObjects = $CMObject.GetCacheInfo() 
 
        #Delete Cache element 
        $CMCacheObjects.GetCacheElements() | Where-Object {$_.ContentID -eq $CacheItemToDelete} |  
            ForEach-Object {  
                $CMCacheObjects.DeleteCacheElement($_.CacheElementID) 
            } 
    }  
} 
 
##Main Script 
 
#Reset progress Counter 
$ProgressCounter = 0 
 
#Check for installed applications (adapted) 
Foreach ($Application in $CM_Applications) { 
 
    #Show progrss bar 
    If ($CM_Applications.Count -ne $null) {  
        $ProgressCounter++ 
        Write-Progress -Activity 'Processing Applications' -CurrentOperation $Application.FullName -PercentComplete (($ProgressCounter / $CM_Applications.Count) * 100) 
        Start-Sleep -Milliseconds 400 
    } 
 
    $Application.Get() 
 
    #Enumerate all deployment types for an application 
    Foreach ($DeploymentType in $Application.AppDTs) { 
        If ($Application.InstallState -eq "Installed" -and $Application.IsMachineTarget) { 
 
            #Get content ID for specific application deployment type 
            $AppType = "Install",$DeploymentType.Id,$DeploymentType.Revision 
            $Content = Invoke-WmiMethod -Namespace root\ccm\cimodels -Class CCM_AppDeliveryType -Name GetContentInfo -ArgumentList $AppType 
 
            #Call Remove-CacheItem function  
            Remove-CacheItem -CacheTD $Content.ContentID -CacheN $Application.FullName 
        } 
    } 
} 
 
#Reset progress Counter 
$ProgressCounter = 0 
 
#Check for installed packages 
Foreach ($Package in $CM_Packages) { 
 
    #Show progrss bar 
    If ($CM_Packages.Count -ne $null) {  
        $ProgressCounter++ 
        Write-Progress -Activity 'Processing Packages' -CurrentOperation $Package.PackageName -PercentComplete (($ProgressCounter / $CM_Packages.Count) * 100) 
        Start-Sleep -Milliseconds 800 
    } 
 
    If ($Package.LastRunStatus -eq "Succeeded" -and $Package.RepeatRunBehavior -ne "RerunAlways" -and $Package.RepeatRunBehavior -ne "RerunIfSuccess") { 
 
        #Call Remove-CacheItem function 
        Remove-CacheItem -CacheTD $Package.PackageID -CacheN $Package.PackageName 
    }    
} 
 
#Reset progress Counter 
$ProgressCounter = 0 
 
#Check for installed updates 
Foreach ($Update in $CM_Updates) { 
 
    #Show Progrss bar 
    If ($CM_Updates.Count -ne $null) {   
        $ProgressCounter++ 
        Write-Progress -Activity 'Processing Updates' -CurrentOperation $Update.Title -PercentComplete (($ProgressCounter / $CM_Updates.Count) * 100) 
    } 
 
    If ($Update.Status -eq "Installed") { 
 
        #Call Remove-CacheItem function  
        Remove-CacheItem -CacheTD $Update.UniqueID -CacheN $Update.Title 
    } 
} 
 
#Sort by size descending 
$Result =  $Global:Result | Sort-Object Size`(MB`) -Descending 
 
#Calculate total deleted size 
$TotalDeletedSize = $Result | Measure-Object -Property Size`(MB`) -Sum | Select -ExpandProperty Sum 
 
#Build result object 
$ResultProps = [ordered]@{ 
    'DeletionDate' = $Date 
    'Name' = 'Total Size of Items Deleted in MB:' 
    'ID' = '' 
    'Location' = '' 
    'Size(MB)' = '' 
    'TotalDeleted(MB)' = $TotalDeletedSize 
} 
 
#Add total items deleted to result object 
$Result += New-Object PSObject -Property $ResultProps 
 
#Write result object to csv file (append) 
$Result | Export-Csv -Path $ResultCSV -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Append -Force 
 
#Write to console 
$Result | Format-Table Name,TotalDeleted`(MB`)