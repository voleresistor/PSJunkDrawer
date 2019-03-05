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