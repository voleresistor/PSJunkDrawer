<#

FileName: UsefulFunctions.ps1
Purpose: Simple storage for functions that are useful to more than one script
Author: Andrew Ogden
Email: andrew.ogden@dxpe.com
Last edit: 11-02-17 - Initial creation

Get-Help boilerplate:

<#
    .Synopsis
    Blah
    
    .Description
    Blah
    
    .Parameter ParameterName
    What parameter does
    
    .Example
    Example
    
    What example does
#>

#>

function Write-Log
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,Position=2)]
        [string]$LogPath,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$TimeStamp = (Get-DateTimeStamp).Time,

        [Parameter(Mandatory=$false)]
        [string]$Datestamp = (Get-DateTimeStamp).Date,

        [Parameter(Mandatory=$false)]
        [string]$Component,

        [Parameter(Mandatory=$false)]
        [string]$Context,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Warning','Error','Verbose')]
        [string]$Type = 'Info',

        [Parameter(Mandatory=$false)]
        [string]$Thread,

        [Parameter(Mandatory=$false)]
        [string]$File
    )

    # Formatted to be easily parsed by cmtrace.exe
    $LogMessage = "<![LOG[$Message]LOG]!><time=`"$TimeStamp`" date=`"$DateStamp`" component=`"$Component`" context=`"$Context`" type=`"$Type`" thread=`"$Thread`" file=`"$File`">"

    # Introduce some extremely simple error checking
    # This means we'll have to do something with the return value in the calling script
    try
    {
        Add-Content -Value $LogMessage -Path $LogPath -ErrorAction Stop
        Start-Sleep -Milliseconds 200
    }
    catch
    {
        Write-Verbose -Message $_.Exception.Message
        Start-Sleep -Milliseconds 200
    }
}

function Get-DateTimeStamp
{
    [CmdletBinding()]
    param
    (
        [int]$HoursAgo,
        [int]$DaysAgo
    )

    # Convert everything to hours
    if ($DaysAgo)    
    {
        $HoursAgo = $DaysAgo * 24
    }

    # Don't forget that we can just get right now
    if (!($HoursAgo))
    {
        $HoursAgo = 0
    }

    # Format the time
    [datetime]$DateTime = (Get-Date).AddDays(-$HoursAgo)
    $TimeStamp = "$($DateTime.Hour):$($DateTime.Minute):$($DateTime.Second).$($DateTime.Millisecond)+000"

    # Format the date
    $Month = "{0:D2}" -f $($DateTime.Month)
    $Day = "{0:D2}" -f $($DateTime.Day)
    $DateStamp = "$Month-$Day-$($DateTime.Year)"

    $MyDate = New-Object -TypeName psobject
    $MyDate | Add-Member -MemberType NoteProperty -Name Date -Value $DateStamp
    $MyDate | Add-Member -MemberType NoteProperty -Name Time -Value $TimeStamp

    # Return custom object with date and time stamp formatted for cmtrace logging
    return $MyDate
}

function Add-FileNameDate
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$FilePath
    )

    # Gather data with gross overuse of -split
    $LogDate = (Get-DateTimeStamp).Date
    $FileName = ($FilePath -split ('\\'))[-1]
    $FileExt = ($FileName -split ('\.'))[-1]
    $FileName = ($FileName -split ('\.'))[0]
    $FilePath = ($FilePath -split("\\$FileName"))[0]

    # Build something
    $FileName = "$(($FileName -split ('\.'))[0])_$LogDate.$FileExt"
    $NewPath = "$FilePath\$FileName"

    return $NewPath
}

function Get-InstalledSoftware
{
    <#
    .Synopsis
    Displays information about installed software on local and remote computers.
    
    .Description
    Collect and display information about installed software on local and remote computers.
    Gathers AppName, AppVersion, AppVendor, Install Date, Uninstall Key, and AppGUID.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Parameter IncludeUpdates
    A switch which enables inclusion of removable software updates in the list of software.

    .Parameter ProductName
    Name of product to search for.

    .Parameter ProductGuid
    GUID to search for.
    
    .Example
    Get-InstalledSoftware
    
    Get data from the local computer
    
    .Example
    Get-InstalledSoftware -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    
    .Example
    Get-InstalledSoftware -Computername computer1 -IncludeUpdates
    
    Get information about installed apps, including updates, from a remote computer
    #>
    param
    (
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ComputerName = $env:computername,

        [parameter(Mandatory=$false)]
        [switch]$IncludeUpdates,

        [parameter(Mandatory=$false)]
        [string]$ProductName,

        [parameter(Mandatory=$false)]
        [string]$ProductGUID
    )
           
    begin
    {
        $UninstallRegKeys=
        @(
            "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
            "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
        )
        
        $AllMembers = @()
    }
                
    process
    {
        #Cycle through list of computers
        foreach($Computer in $ComputerName)
        {
            if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0))
            {
                continue
            }
            
            #Gather data based on each reg key
            foreach($UninstallRegKey in $UninstallRegKeys)
            {
                try
                {
                    $HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)
                    $UninstallRef = $HKLM.OpenSubKey($UninstallRegKey)
                    $Applications = $UninstallRef.GetSubKeyNames()
                }
                catch
                {
                    Write-Verbose "Failed to read $UninstallRegKey"
                    Continue
                }
                
                #Populate app data
                foreach ($App in $Applications)
                {
                    $AppRegistryKey = $UninstallRegKey + "\\" + $App
                    $AppDetails = $HKLM.OpenSubKey($AppRegistryKey)

                    #Skip this object if there's no display name or it's an update and we aren't including them
                    if((!$($AppDetails.GetValue("DisplayName"))) -or (($($AppDetails.GetValue("DisplayName")) -match ".*KB[0-9]{7}.*") -and (!$IncludeUpdates)))
                    {
                        continue
                    }

                    #Match ProductName if provided
                    if ($ProductName -and !($($AppDetails.GetValue("DisplayName")) -match $ProductName))
                    {
                        continue
                    }

                    #Match ProductGUID if provided
                    if ($ProductGUID -and !($($AppDetails.GetValue("UninstallString")) -match $ProductGUID))
                    {
                        continue
                    }

                    #Create the object
                    $OutputObj = New-Object -TypeName PSobject
                    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()

                    #Begin populating the object
                    #Start by gathering the easy data
                    $OutputObj | Add-Member -MemberType NoteProperty -Name UninstallKey -Value $($AppDetails.GetValue("UninstallString"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $($AppDetails.GetValue("DisplayName"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $($AppDetails.GetValue("DisplayVersion"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $($AppDetails.GetValue("Publisher"))

                    #Extract the GUID from the MSI uninstall key
                    if ($($AppDetails.GetValue("UninstallString")) -match "msiexec(.exe){0,1} \/[XIxi]{1}\{.*")
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $($($AppDetails.GetValue("UninstallString")) -replace "msiexec(.exe){0,1} \/[XIxi]{1}\{","{")
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value ''
                    }

                    #Build a human readable date string
                    $RawDate = $AppDetails.GetValue("InstallDate")

                    if ($RawDate)
                    {
                        $RawYear = ($RawDate -split "[0-9]{4}$")[0]
                        $RawDM = ($RawDate -split "^[0-9]{4}")[1]
                        $RawMonth = ($RawDM -split "[0-9]{2}$")[0]
                        $RawDay = ($RawDM -split "^[0-9]{2}")[1]
                    
                        [datetime]$FormattedDate = "$RawMonth/$RawDay/$RawYear"
                        $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value $($FormattedDate.ToShortDateString())
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value ''
                    }

                    #Determine if app is 64/32 bit. This assumes that all clients are 64 bit
                    if($UninstallRegKey -match "Wow6432Node")
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value 'x86'
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value 'x64'
                    }

                    $AllMembers += $OutputObj
                }   
            }
        }
    }
                
    end
    {
        #Return the data we discovered
        return $AllMembers
    }
}