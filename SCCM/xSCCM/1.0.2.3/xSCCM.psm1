<#
    Custom functions for common operations in SCCM and MDT.
    
    Created 06/20/16
    
    Changelog:
        06/20/16 - v 1.0.0
            Initial build
            Added Split-DriverSource
        03/16/17 - v 1.0.1
            Added Get-CMCollectionMembership
        06/27/17 - v 1.0.2.2
            Added Clear-CMCache
            Added Get-UpgradeReadiness
            Added Get-UpgradeHistory
            Update module manifest to require PS5 for use of Class in new functions
        06/29/17 - v1.0.2.3
            Add help comments boilerplate
            Add help comments to Split-DriverSource and Update-CMSiteName
#>

<#
    Help comments boilerplate

    <# 
        .SYNOPSIS 
            Short description.
        .DESCRIPTION
            Long description.
        .PARAMETER  Param1 
            Description of Param1.
        .PARAMETER  Param2 
            Description of Param2.
        .EXAMPLE 
            Get-Example -Param1
            Example 1
        .EXAMPLE
            Get-Example -Param2
            Example 2
        .Notes 
            Author : 
            Email  : 
            Date   : 
            WebSite: 
    #> 
#>

#region Split-DriverSource 
function Split-DriverSource
{
    <# 
        .SYNOPSIS 
            Reduce the size of driver source packs by removing files that don't match a filter.
        .DESCRIPTION
            Remove extraneous driver files to help manage the size of driver source folders. Driver packs ship with many extra files and this function is intended to help clean those up.
        .PARAMETER  SourcePath 
            Path to source folder.
        .PARAMETER  DestPath 
            Path to output copied files.
        .EXAMPLE 
            Split-DriverSource -SourcePath "C:\temp\DriverSource" -DestPath "C:\temp\DriverClean"
            Example 1
        .Notes 
            Author : Andrew Ogden
            Email  : andrew.ogden@dxpe.com
            Date   : 
    #>
    param
    (
        [string]$SourcePath,
        [string]$DestPath
    )
    
    Import-Module PSAlphaFS
    
    $DestFileCount = 0
    $SourceFileCount = 0
    
    if (!(Test-Path -Path $DestPath))
    {
        New-Item -Path $DestPath -ItemType Directory | Out-Null
    }
    
    $FullSource = Get-ChildItem -Path $SourcePath -Recurse | Select-Object Directory,FullName,Name,Extension
    $SourceFileCount = ($FullSource | ?{$_.Attributes -ne 'Directory'}).Count
    
    $DriverFiles = $FullSource | ?{
        ($_.Extension -eq '.bin') -or
        ($_.Extension -eq '.cab') -or
        ($_.Extension -eq '.cat') -or
        ($_.Extension -eq '.dll') -or
        ($_.Extension -eq '.inf') -or
        ($_.Extension -eq '.ini') -or
        ($_.Extension -eq '.oem') -or
        ($_.Extension -eq '.sys')
    }
    $DestFileCount = ($DriverFiles | ?{$_.Attributes -ne 'Directory'}).Count
    
    foreach ($File in $DriverFiles)
    {
        $SourceDir = $File.Directory
        $SourceFullName = $File.FullName# -replace ('\\','\\')
        #$SourceName = $File.Name
        #$ReplacePath = $SourceFullName
        $Source = $SourcePath -replace ('\\','\\')
        $Dest = $DestPath -replace ('\\','\\')
        $DestDir = $SourceDir -replace ("$Source", "$Dest")

        if (!(Test-Path -Path $DestDir))
        {
            New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
        }
        
        Copy-Item -Path $SourceFullName -Destination $DestDir -Force | Out-Null
    }
    
    $TotalStats = New-Object -TypeName psobject
    $TotalStats | Add-Member -MemberType NoteProperty -Name FilesKept -Value $DestFileCount
    $TotalStats | Add-Member -MemberType NoteProperty -Name FilesDropped -Value ($SourceFileCount - $DestFileCount)
    $TotalStats | Add-Member -MemberType NoteProperty -Name OriginalFiles -Value $SourceFileCount
    $TotalStats | Add-Member -MemberType NoteProperty -Name SourceSizeGB -Value (Get-FolderSize -Path $SourcePath).SizeinGB
    $TotalStats | Add-Member -MemberType NoteProperty -Name NewSizeGB -Value (Get-FolderSize -Path $DestPath).SizeInGB
    
    return $TotalStats
}
<#
    Example Output:
    
    PS C:\> Split-DriverSource -SourcePath '\\<Driversource>\Windows7x64-old' -DestPath '<Driversource>\Windows7x64'

    FilesKept     : 932
    FilesDropped  : 1526
    OriginalFiles : 2458
    SourceSizeGB  : 1.29
    NewSizeGB     : 0.59
    
    PS C:\>
#>

#endregion

#region Update-CMSiteName
function Update-CMSiteName
{
    <# 
        .SYNOPSIS 
            Update CM site description.
        .DESCRIPTION
            Microsoft doesn't provide a simple method to change a site name from within the CM console. This function uses WMI calls to edit the site description.
        .PARAMETER  SiteName 
            Three letter site code.
        .PARAMETER  Siteserver 
            FQDN of a site server for the site you wish to change.
        .PARAMETER NewSiteDesc
            New description to apply to the site.
        .EXAMPLE 
            Update-CMSiteName -SiteName TST -SiteServer cm01.test.com -NewSiteDesc "Test.com SCCM Site - TST - v1606"
            Update the site description of site named TST on server cm01.test.com.
        .Notes 
            Author : Andrew Ogden
            Email  : andrew.ogden@dxpe.com
            Date   : 
    #>
    param
    (
        [string]$SiteName = 'HOU',
        [string]$SiteServer = 'housccm03.dxpe.com',
        [string]$NewSiteDesc
    )
    
    $FullSite = Get-WmiObject -Class 'SMS_SCI_SiteDefinition' -Namespace "root/SMS/site_$SiteName" -ComputerName $SiteServer
    
    if (!($NewSiteDesc))
    {
        Write-Host "Current site description is - $($FullSite.SiteName)"
        $NewSiteDesc = Read-Host -Prompt "Enter new description: "   
    }
    
    $OldSiteDesc = $FullSite.SiteName
    $FullSite.SiteName = $NewSiteDesc
    $FullSite.Put()
    
    $CurrentSiteDesc = (Get-WmiObject -Class 'SMS_SCI_SiteDefinition' -Namespace "root/SMS/site_$SiteName" -ComputerName $SiteServer).SiteName
    if ($CurrentSiteDesc -ne $NewSiteDesc)
    {
        Write-Host 'There was an error updating the site description.' -ForegroundColor Red
    }
    else
    {
        Write-Host "Site description successfully updated.`r`nOld: $OldSiteDesc`r`nNew: $NewSiteDesc"
    }
}
#endregion

#region Get-CMCollectionMembership
Function Get-CMCollectionMembership
{
    <# 
            .SYNOPSIS 
                Determine the SCCM collection membership.
            .DESCRIPTION
                This function allows you to determine the SCCM collection membership of a given user/computer.
            .PARAMETER  Type 
                Specify the type of member you are querying. Possible values : 'User' or 'Computer'
            .PARAMETER  ResourceName 
                Specify the name of your member : username or computername.
            .PARAMETER  SiteServer
                Specify the name of the site server to query.
            .PARAMETER  SiteCode
                Specify the site code on the targeted server.
            .EXAMPLE 
                Get-Collections -Type computer -ResourceName PC001
                Get-Collections -Type user -ResourceName User01
            .Notes 
                Author : Antoine DELRUE 
                WebSite: http://obilan.be 
    #> 

    param(
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("User", "Computer")]
    [string]$Type,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$ResourceName,

    [Parameter(Mandatory=$false,Position=3)]
    [string]$SiteServer = 'housccm03.dxpe.com',

    [Parameter(Mandatory=$false,Position=4)]
    [string]$SiteCode = 'HOU'
    ) #end param

    Switch ($type)
        {
            User {
                Try {
                    $ErrorActionPreference = 'Stop'
                    $resource = Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -Class "SMS_R_User" | ? {$_.Name -ilike "*$resourceName*"}                            
                }
                catch {
                    Write-Warning ('Failed to access "{0}" : {1}' -f $SiteServer, $_.Exception.Message)
                }

            }

            Computer {
                Try {
                    $ErrorActionPreference = 'Stop'
                    $resource = Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -Class "SMS_R_System" | ? {$_.Name -ilike "$resourceName"}                           
                }
                catch {
                    Write-Warning ('Failed to access "{0}" : {1}' -f $SiteServer, $_.Exception.Message)
                }
            }
        }

    $ids = (Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -Class SMS_CollectionMember_a -filter "ResourceID=`"$($Resource.ResourceId)`"").collectionID
    # A little trick to make the function work with SCCM 2012
    if ($ids -eq $null)
    {
            $ids = (Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -Class SMS_FullCollectionMembership -filter "ResourceID=`"$($Resource.ResourceId)`"").collectionID
    }

    $array = @()

    foreach ($id in $ids)
    {
        $Collection = get-WMIObject -ComputerName $SiteServer -namespace "root\sms\site_$SiteCode" -class sms_collection -Filter "collectionid=`"$($id)`""
        $Object = New-Object PSObject
        $Object | Add-Member -MemberType NoteProperty -Name "Collection Name" -Value $Collection.Name
        $Object | Add-Member -MemberType NoteProperty -Name "Collection ID" -Value $id
        $Object | Add-Member -MemberType NoteProperty -Name "Comment" -Value $Collection.Comment
        $array += $Object
    }

    return $array
}
#endregion

#region Clear-CMCache
function Clear-CMCache
{
    <# 
        .SYNOPSIS 
            Clear CM and WU caches. Requires elevation to target local computer.
        .DESCRIPTION
            Clear CM cache and optionally the reset WU cache. This can help save disk space, force a computer to re-download an SCCM package or troubleshoot Windows Update errors. If the target is the local computer, elevation is required.
        .PARAMETER  ComputerName 
            Specify the computer or comma separated list of computers to clean up.
        .PARAMETER  ResetWUCache 
            Switch to enable cleanup of WU cache.
        .EXAMPLE 
            Clear-CMCache -ComputerName Computer1,Computer2
            Clear-CMCache -ComputerName Computer1,Computer2 -ResetWUCache
        .Notes 
            Author : Andrew Ogden
            Email: andrew.ogden@dxpe.com
            Date: 06/26/2017
            Updated: 06/27/2017
            Based on code provided by user 0byt3 in this Reddit thread: https://www.reddit.com/r/SCCM/comments/3m8uh9/script_sms_client_to_clear_cache_then_install/
    #>

    param
    (
        [array]$ComputerName,
        [switch]$ResetWUCache
    )

    For ($i = 0; $i -lt $($ComputerName.Count); $i++)
    {
        # Create a session object for easy cleanup so we aren't leaving half-open
        # remote sessions everywhere
        try
        {
            Write-Progress -Activity "Clearing remote caches..." -Status "$($ComputerName[$i]) ($i/$($ComputerName.Count))" -PercentComplete ($($i/$($ComputerName.Count))*100)
            $CacheSession = New-PSSession -ComputerName $ComputerName[$i] -ErrorAction Stop
        }
        catch
        {
            Write-Host "$(Get-Date -UFormat "%m/%d/%y - %H:%M:%S") > ERROR: Failed to create session for $($ComputerName[$i])"
            Write-Host -ForegroundColor Yellow -Object $($error[0].Exception.Message)
            continue
        }

        # How big is the CM Cache?
        # We'll access the remote session a first time here to set up the COM object
        # and gather some preliminay data. We're also saving the cache size into a
        # local variable here for some reporting
        $SpaceSaved = Invoke-Command -Session $CacheSession -ScriptBlock {
            # Create CM object and gather cache info
            $cm = New-Object -ComObject UIResource.UIResourceMgr
            $cmcache = $cm.GetCacheInfo()
            $CacheElements = $cmcache.GetCacheElements()

            # Report space in use back to the local variable in MB
            $(($cmcache.TotalSize - $cmcache.FreeSize))
         }

        # Clear the CM cache
        # Now we're accessing the session a second time to clear the cache (assuming it's not  already empty)
        Invoke-Command -Session $CacheSession -ScriptBlock {
            if ($CacheElements.Count -gt 0)
            {
                # Echo total cache size
                Write-Host "$(($cmcache.TotalSize - $cmcache.FreeSize))" -NoNewline -ForegroundColor Yellow
                Write-Host " MB used by $(($cmcache.GetCacheElements()).Count) cache items on $env:computername"

                # Remove each object
                foreach ($CacheObj in $CacheElements)
                {
                    # Log individual elements
                    $eid = $CacheObj.CacheElementId
                    #Write-Host "Removing content ID $eid with size $(($CacheObj.ContentSize) / 1000)MB from $env:ComputerName"

                    # Delete content object
                    $cmcache.DeleteCacheElement($eid)
                }
            }
            else
            {
                Write-Host "Cache already empty on $env:ComputerName!"
            }
        }

        # Clean the WU cache (if requested)
        if ($ResetWUCache)
        {
            # This time we're going to access the remote session to count the size of the 
            # WU cache and add that to the existing variable
            $SpaceSaved += Invoke-Command -Session $CacheSession -ScriptBlock {
                $SizeCount = 0
                foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
                {
                    $SizeCount += $f.Length
                }

                # Report size in mb
                $SizeCount / 1mb
            }

            # Now we hop back into the remote session again to finish clearing
            # out the WU cache
            Invoke-Command -Session $CacheSession -ScriptBlock {
                Stop-Service wuauserv -Force -WarningAction SilentlyContinue

                Write-Host "Resetting WU Cache on $env:ComputerName..."
                Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Force -Recurse

                # Restart WU and wait a few seconds for it to create a new cache folder
                Start-Service wuauserv -WarningAction SilentlyContinue
                Start-Sleep -Seconds 10

                # Verify that a new cache folder was created and throw an error if not
                if (!(Get-Item -Path "$env:SystemRoot\SoftwareDistribution"))
                {
                    Write-Host -Object "Failed to recreate SoftwareDistribution folder!" -ForegroundColor Red
                }
            }

            # We're accessing the session again a final time to determine the new size of the
            # WU cache to subtract from our saved space
            $SpaceSaved -= Invoke-Command -Session $CacheSession -ScriptBlock {
                $SizeCount = 0
                foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
                {
                    $SizeCount += $f.Length
                }

                # Report size in mb
                $SizeCount / 1mb
            }
        }

        # Report the space saved
        Write-Host -Object "Space saved on $($ComputerName[$i]): " -NoNewline
        Write-Host -Object $("{0:N2}" -f $SpaceSaved) -ForegroundColor Green -NoNewline
        Write-Host -Object " MB"

        # Clean up the session when done
        try
        {
            Remove-PSSession -Session $CacheSession -ErrorAction Stop
        }
        catch
        {
            Write-Host "ERROR: Failed to clean up session for $($ComputerName[$i])"
            Write-Host -ForegroundColor Yellow -Object $($error[0].Exception.Message)
            continue
        }

        # Clean up this variable to ensure that it doesn't bleed into subsequent iterations
        Clear-Variable -Name SpaceSaved
    }
}

<#
Example output:

PS C:\temp> Clear-CMCache -ComputerName dxpepc2314 -ResetWUCache
12796 MB used by 1411 cache items on DXPEPC2314
Resetting WU Cache on DXPEPC2314...
Space saved on dxpepc2314: 15,452.77 MB

PS C:\temp>
#>
#endregion

#region Get-UpgradeReadiness
function Get-UpgradeReadiness
{
    <# 
        .SYNOPSIS 
            Determine if any obvious hardware or OS configurations are likely to prevent a successful upgrade to Windows 10.
        .DESCRIPTION
            Checks current OS, SKU, architecture, memory, and free disk space to determine eligibility for Windows 10 upgrade. Threshholds for eligibility are user modifiable.
        .PARAMETER  ComputerName 
            Specify the computer or comma separated list of computers to evaluate.
        .PARAMETER  MinDisk 
            Minimum free GB for upgrade eligibility. Entered as a float. Default: 14.5
        .PARAMETER  MinMemory 
            Minimum memory in GB for upgrade eligibility. Entered as a float. Default: 2.75
        .PARAMETER  CsvOutFile 
            Results can be saved in the specified file in CSV format. Useful when evaluating a large array of computers at once.
        .EXAMPLE 
            Get-UpgradeReadiness -ComputerName Computer1,Computer2
            Get-UpgradeReadiness -ComputerName Computer1,Computer2 -CsvOutFile "C:\temp\Upgradecheck.csv"
        .Notes 
            Author : Andrew Ogden
            Email: andrew.ogden@dxpe.com
            Date: 02/07/2017
            Updated: 06/27/17
    #>

    #requires -Version 5.0
    Param
    (
        [array]$ComputerName = @('localhost'),
        [float]$MinDisk = 14.5,
        [float]$MinMemory = 2.75,
        [string]$CsvOutFile
    )

    #Define our custom class
    class UpgradeData
    {
        [string]
        $ComputerName

        [float]
        $MemoryGB

        [string]
        $OSArchitecture

        [string]
        $OSEdition

        [float]
        $DiskFreeGB

        [string]
        $UserName

        [string]
        $OSVersion

        [string]
        $UpgradeOK
    }

    #Convert MinDisk and MinMemory to kB and B respectively
    $MinDisk = $MinDisk * 1gb
    $MinMemory = $MinMemory * 1kb * 1024

    #An array to store class objects for each computer
    $UpgradeReadiness = @()

    #Cycle through our clients and gather data
    foreach ($Client in $ComputerName)
    {
        #Create new instance of UpgradeData class and populate the computername
        $ClientReadiness = [UpgradeData]::new()
        $ClientReadiness.ComputerName = $Client

        #Reset all variables
        $ClientAvailable = $false
        $ClientData = $null
        $FormattedMemory = $null
        $FormattedDisk = $null
        $RawDisk = $null

        #If the client is online, gather data and populate the object
        if ((Test-NetConnection -ComputerName $Client -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded -eq 'True')
        {
            #Note that client was online
            $ClientAvailable = $true

            #Get data from WMI classes
            $ClientData = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Client -ErrorAction SilentlyContinue | Select-Object -Property *
            $RawDisk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Client -ErrorAction SilentlyContinue | Where-Object -FilterScript {$_.DeviceId -eq 'C:'}
            $User = (Get-WmiObject -Class win32_ComputerSystem -ComputerName $Client -ErrorAction SilentlyContinue).UserName

            #Format memory and disk size numbers
            $FormattedMemory = "{0:N1}" -f $($ClientData.TotalVisibleMemorySize / 1mb)
            $FormattedDisk = "{0:N1}" -f $($RawDisk.FreeSpace /1gb)

            #Populate disk and memory
            $ClientReadiness.MemoryGB = $FormattedMemory
            $ClientReadiness.DiskFreeGB = $FormattedDisk

            #Get release level (Home/Pro/Ent)
            if (($ClientData.Caption -match 'Enterprise') -eq 'True')
            {
                $ClientReadiness.OSEdition = 'Enterprise'
            }
            elseif (($ClientData.Caption -match 'Professional') -eq 'True')
            {
                $ClientReadiness.OSEdition = 'Professional'
            }
            elseif (($ClientData.Caption -match 'Home') -eq 'True')
            {
                $ClientReadiness.OSEdition = 'Home'
            }

            #Populate other values
            $ClientReadiness.OSArchitecture = $ClientData.OSArchitecture
            $ClientReadiness.OSVersion = $ClientData.Version
            $ClientReadiness.UserName = $User
        }

        #Ugly 'if' chain to determine upgrade eligibility
        if (!($ClientAvailable))
        {
            $ClientReadiness.UpgradeOK = 'Client Unavailable'
        }
        elseif ($ClientData.OSArchitecture -ne '64-bit')
        {
            $ClientReadiness.UpgradeOK = 'Arch Mismatch'
        }
        elseif ($MinDisk -gt $RawDisk.FreeSpace)
        {
            $ClientReadiness.UpgradeOK = 'Insuff Disk'
        }
        elseif (($MinMemory -gt $ClientData.TotalVisibleMemorySize))
        {
            $ClientReadiness.UpgradeOK = 'Insuff Memory'
        }
        else
        {
            $ClientReadiness.UpgradeOK = 'OK'
        }

        #Append this client's data to the total array
        $UpgradeReadiness += $ClientReadiness
    }

    # Generate CSV file
    if ($CsvOutFile)
    {
        # Backup old file if outfile already exists
        if (Test-Path -Path $CsvOutFile)
        {
            Move-Item -Path $CsvOutFile -Destination "$CsvOutFile.old" -Force
        }

        # We set this so that data headers are only included once
        $FirstItem = $true

        # Generate the CSV file by looping through the array of computer objects
        foreach ($Computer in $UpgradeReadiness)
        {
            $CsvData = ConvertTo-Csv -InputObject $Computer -NoTypeInformation -Delimiter ','
            if ($FirstItem -eq $true)
            {
                Add-Content -Value $CsvData[0] -Path $CsvOutFile

                # Disable inclusion of header data for further objects
                $FirstItem = $false
            }
            Add-Content -Value $CsvData[1] -Path $CsvOutFile

            Clear-Variable -Name CsvData
        }
    }

    #Return collected data to console
    Return $UpgradeReadiness
}

<#
Example output:

PS C:\temp> Get-UpgradeReadiness -ComputerName dxpepc2137 | ft

ComputerName MemoryGB OSArchitecture OSEdition  DiskFreeGB UserName OSVersion  UpgradeOK
------------ -------- -------------- ---------  ---------- -------- ---------  ---------
dxpepc2137        3.8 64-bit         Enterprise      409.3          10.0.15063 OK

PS C:\temp>
#>
#endregion

#region Get-UpgradeHistory
function Get-UpgradeHistory
{
    <# 
        .SYNOPSIS 
            Get history report of all previous upgrades.
        .DESCRIPTION
            Gathers data about previous upgrades on the targeted system.
        .PARAMETER  ComputerName 
            Specify the computer or comma separated list of computers to evaluate.
        .EXAMPLE 
            Get-UpgradeHistory -ComputerName Computer1,Computer2
        .Notes 
            Author : Andrew Ogden
            Email: andrew.ogden@dxpe.com
            Date: 03/29/2017
            Updated: 06/27/17
    #>

    #requires -Version 5.0
    Param
    (
        [array]$ComputerName
    )

    # Store collected data
    class UpgradeHistory
    {
        [string]$ComputerName

        [string]$SourceOS

        [string]$SourceEdition

        [string]$SourceBuild

        [string]$UpgradeDate
    }

    # Array of data objects
    $UpgradeHistoryResults = @()

    foreach ($c in $ComputerName)
    {
        # Connect remote reg and get data on upgrade keys
        try
        {
            $RemoteReg = [Microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$c)
            $SetupKey = $RemoteReg.OpenSubKey('SYSTEM\\Setup')
            $UpgradeRecords = $SetupKey.GetSubKeyNames() | Where-Object -FilterScript {$_ -match 'Source OS'}
        }
        catch
        {
            # Create a record to record blank results
            $ClientUpgradeHistory = [UpgradeHistory]::new()
            $ClientUpgradeHistory.ComputerName = $c
            $ClientUpgradeHistory.SourceOS = 'Offline'

            # Add to array
            $UpgradeHistoryResults += $ClientUpgradeHistory
            Clear-Variable ClientUpgradeHistory

            # Continue execution with next target
            continue
        }

        # Record no data and continue if no records exist
        if (!($UpgradeRecords))
        {
            # Create a record to record blank results
            $ClientUpgradeHistory = [UpgradeHistory]::new()
            $ClientUpgradeHistory.ComputerName = $c
            $ClientUpgradeHistory.SourceOS = 'No upgrade data'

            # Add to array
            $UpgradeHistoryResults += $ClientUpgradeHistory
            Clear-Variable ClientUpgradeHistory

            # Continue execution with next target
            $RemoteReg.Close()
            continue
        }

        # Process all present upgrade keys
        foreach ($Record in $UpgradeRecords)
        {
            # Instantiate class and open upgrade key
            $ClientUpgradeHistory = [UpgradeHistory]::new()
            $CurrentRecord = $RemoteReg.OpenSubKey("SYSTEM\\Setup\\$Record")

            # Client name
            $ClientUpgradeHistory.ComputerName = $c

            # Upgrade date
            $Record -match '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' | Out-Null
            $ClientUpgradeHistory.UpgradeDate = $Matches[0]

            # Get source OS Name
            $ClientUpgradeHistory.SourceOS = $CurrentRecord.GetValue('ProductName')

            # Get source edition
            $ClientUpgradeHistory.SourceEdition = $CurrentRecord.GetValue('EditionID')

            # Get source build
            $ClientUpgradeHistory.SourceBuild = $CurrentRecord.GetValue('CurrentBuild')

            # Add collected data to final array
            $UpgradeHistoryResults += $ClientUpgradeHistory

            # Clear variables used in loop
            Clear-Variable ClientUpgradeHistory
        }

        Clear-Variable UpgradeRecords
        $RemoteReg.Close()
    }

    return $UpgradeHistoryResults
}
<#
Example output:

PS C:\temp> Get-UpgradeHistory -ComputerName dxpepc2137

ComputerName  : dxpepc2137
SourceOS      : Windows 7 Enterprise
SourceEdition : Enterprise
SourceBuild   : 7601
UpgradeDate   : 6/22/2017

PS C:\temp>
#>
#endregion