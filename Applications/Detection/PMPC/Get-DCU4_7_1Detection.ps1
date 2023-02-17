<#
    .Synopsis
        Script used for application detection methods
    .DESCRIPTION
        This script is used as part of the Patch My PC Publisher in order to dynamically detect if an application
        is either applicable, or installed. The default variable values are placeholders that are meant to be
        replaced as part of an automatic process.
    .PARAMETER AppToSearch
        A pattern used to search for displayName in the uninstall registry key.
    .PARAMETER AppToAvoid
        A pattern used to reject similar applications to ensure the proper application is detected
    .PARAMETER MSICodeToSearch
        A MSI code used to search for in the uninstall registry key.
    .PARAMETER ApplicationVersionToSearch
        The specific version of the application we are searching for.
    .PARAMETER ApplicationVersionFilter
        A version filter used to filter the version we will search against. This is useful when we need
        to only check against a certain major version. For example, you might have a version fitler
        of 11.* to ensure we only check for the major version 11 of an app. With this, we would make sure
        that version 12+ of an application would not trigger the script to return installed or applicable
    .PARAMETER Architecture
        The architecture of the application we are searching for. This can be 'Both','x86', or 'x64'
    .PARAMETER Purpose
        The purpose of the script, this is either 'Detection' or 'Requirement'
    .PARAMETER HivesToSearch
        Sets the registry hives to search under.
    .PARAMETER InstallerType
        Sets the installer type that we are searching for. This can be either EXE, MSI or ANY.
        The registry key that we find the installed software under must match this installer type.
        For an MSI the key must be a GUID. For an EXE the key must NOT be a GUID. For ANY the key
        format doesn not matter.
    .PARAMETER RegKeyDetection
        This parameter accepts a hash table in a specific format. This hash table is used to perform
        a check of specific registry values meeting a condition. This allows for the script to have
        additional flexibility for complex application detection such as Google Chrome 32 bit or the
        Adobe Acrobat tracks. An example hash table is below.

        $RegKeyDetection = @{
            @{
                'SOFTWARE\Google\Update\ClientState\{8A69D345-D564-463C-AFF1-A69D9E530F96}' = 'ap'
            } = @{
                    Value       = 'x64'
                    WOW6432Node = $true
                    Operator    = '-match'
                };
            @{
                'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{018CF00D-E79A-4F40-B2B6-EA76AACF88DC}' = 'InstallDate'
            } = @{
                    Value       = '1'
                    WOW6432Node = $false
                    Operator    = '-ge'
            };
        }
    .PARAMETER LogFileName
        The name of the log file that will be used. The location is automatically determined based on who
        is running the script, and whether the CCM logs directory is available.

    .Notes
        FileName:    SoftwareDetectionScript.PS1
        Author:      PatchMyPC
        Contact:     support@patchmypc.com
        Created:     2019-07-24
        Updated:     2021-05-26
        License:     Copyright Patch My PC, LLC all rights reserved

        Version 1.0
            - Initial release
        Version 1.1
            - Get-PMPInstalledSoftwares reads only relevant registry values to workaround Get-ItemProperty bug on corrupted registry data
        Version 1.2
            - Enhancement on versions comparison
        Version 1.3
            - Fix compatibility issue with PowerShell v2
        Version 1.4
            - Use environment variables instead of hardcoded path
        Version 1.5
            - Remove requirement for the UninstallString
        Version 1.6
            - Remove output when creating programData folder
        Version 2.0
            - Add ability to use as a requirement rule
            - Allow specifying the architecture
            - Add check for running as user, or system
            - Parameterize the script
            - Add ability to run with -verbose
            - Add proxy function so -verbose writes out to log file
        Version 2.1
            - Change the check for system to look for the SID and not the username
            - Change to using a $HivesToSearch parameter to simply allow input of what hives to search
        Version 2.2
            - Allow for a ApplicationVersionFilter to limit version selection. This is useful for selecting on a specific major version
        Version 2.3
            - Fixed an issue where the $ApplicationVersionToSearch would be populated with * instead of the actual version to search
        Version 2.4
            - Adjusted the version comparison condition. We only check the version extracted from display name if the displayversion is empty
            - Small adjustment to logging to appropriately log out $HivesToSearch
        Version 2.5
            - Fix compatibility issue with PowerShell v2
        Version 2.6
            - Fixed an issue where improper versions will break detection. Some vendors put datetime stamps in their version resulting
                in an invalid version because some of the version parts are not a valid 32 bit signed integer. i.e. '3.7.9.201912052356''
        Version 2.7
            - Add support for specifying arbitrary registry key / property / value which must meet a condition for detection or requirement to pass
            - Add support for specifying the 'Installer Type' which will validate installer type that we are detecting by checking if the key the
                found app is under is a GUID or not.
            - Use proxy functions for all logging so that we can write to the console and to the log file seamlessly
            - Only trim DisplayVersion if the field is not $null or empty to prevent throwing an exception
        Version 2.8
            - Resolve logging issues that caused incorrect detection for ConfigMgr.
        Version 2.9
            - Cast DisplayVersion to a string before performing a .Trim because some vendors store the DisplayVersion as a DWORD in the registry.
        Version 3.0
            - Extract the version from DisplayVersion field using regex. Some vendors will put more than just a version in the DisplayVersion field.
                This is the same function we use to extract the version from the DisplayName field.
            - Rename functions to better match their purpose.
                Get-PMPVersionFromString > ConvertTo-PMPVersion
                Get-PMPVersionFromName > Get-PMPVersionFromString
            - ErrorAction set to SilentlyContinue for RegKeyDetection checks in case the specified key does not exist.
        Version 3.1
            - Adjust Test-PMPRegKeyAction to use 'return' keyword.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AppToSearch = 'Dell Command* Update*',
    [Parameter(Mandatory = $false)]
    [string]$AppToAvoid = '*Windows*',
    [Parameter(Mandatory = $false)]
    [string]$AppMSICodeToSearch = '',
    [Parameter(Mandatory = $false)]
    [string]$ApplicationVersionToSearch = '4.7.1',
    [Parameter(Mandatory = $false)]
    [string]$ApplicationVersionFilter = '*',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Both', 'x86', 'x64')]
    [string]$Architecture = 'Both',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Detection', 'Requirement')]
    [string]$Purpose = 'Detection',
    [Parameter(Mandatory = $false)]
    [ValidateSet('HKLM', 'HKCU')]
    [string[]]$HivesToSearch = 'HKLM',
    [Parameter(Mandatory = $false)]
    [ValidateSet('EXE', 'MSI', 'ANY')]
    [string]$InstallerType = 'Any',
    [Parameter(Mandatory = $false)]
    [hashtable]$RegKeyDetection = @{@{'SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings' = 'AppCode'} = @{Value = 'Classic';WOW6432Node = $False; Operator = '-like'};},
    [Parameter(Mandatory = $false)]
    [string]$LogFileName = "PatchMyPC-SoftwareDetectionScript.log"
)
#Set variables#
# Script version that will be noted in log files
$ScriptVersion = '3.1'

#region functions
function Get-CMLogDirectory {
    [CmdletBinding()]param()

    try {
        $LogDir = (Get-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\Logging\@Global\ -Name LogDirectory -ErrorAction Stop).LogDirectory
    }
    catch {
        $LogDir = $null
    }
    Write-Verbose "CCM Log Directory = $LogDir"
    return $LogDir
}
function Get-CurrentUser {
    [CmdletBinding()]param()
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Verbose "Current User = $($currentUser.Name)"
    return $currentUser
}

function Test-IsRunningAsAdministrator {
    [CmdletBinding()]param()
    $currentUser = Get-CurrentUser
    $IsUserAdmin = (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Verbose "Current User Is Admin = $IsUserAdmin"

    return $IsUserAdmin
}

function Test-IsRunningAsSystem {
    [CmdletBinding()]param()
    $RunningAsSystem = (Get-CurrentUser).User -eq 'S-1-5-18'
    Write-Verbose "Running as system = $RunningAsSystem"
    return $RunningAsSystem
}

function Get-PMPLogPath {
    [CmdletBinding()]param()
    <#
        Returns the log path to put the log folder in
        If running as a user, it will use their temp directory
        If running as system, it will return the CCM Logs directory if found, otherwise it will use a custom PatchMyPCIntuneLogs folder in programdata
    #>
    $LogPath = $env:temp

    if (Test-IsRunningAsSystem) {
        # Script is running as system
        $CMLogDir = Get-CMLogDirectory
        if ($null -ne $CMLogDir -and (Test-Path -Path $CMLogDir)) {
            $LogPath = $CMLogDir
        }
        else {
            if (Test-Path -Path "$env:programdata\PatchMyPCIntuneLogs") {
                # Found $env:programdata\PatchMyPCIntuneLogs, will save log here
                $LogPath = "$env:programdata\PatchMyPCIntuneLogs"
            }
            else {
                Try {
                    # Didn't find $env:windir\CCM\Logs or $env:programdata\PatchMyPCIntuneLogs, assuming Intune try to create $env:programdata\PatchMyPCIntuneLogs
                    $null = New-Item -ItemType Directory -Force -Path "$env:programdata\PatchMyPCIntuneLogs" -ErrorAction SilentlyContinue
                    $LogPath = "$env:programdata\PatchMyPCIntuneLogs"
                }
                Catch {
                    # Unable to create folder
                }
            }
        }
    }
    Write-Verbose "LogPath = $LogPath"
    return $LogPath
}

Function Write-CCMLogEntry {
    <#
        .SYNOPSIS
            Write to a log file in the CMTrace Format
        .DESCRIPTION
            The function is used to write to a log file in a CMTrace compatible format. This ensures that CMTrace or OneTrace can parse the log
            and provide data in a familiar format.
        .PARAMETER Value
            String to be added it to the log file as the message, or value
        .PARAMETER Severity
            Severity for the log entry. 1 for Informational, 2 for Warning, and 3 for Error.
        .PARAMETER Component
            Stage that the log entry is occuring in, log refers to as 'component.'
        .PARAMETER FileName
            Name of the log file that the entry will written to - note this should not be the full path.
        .PARAMETER Folder
            Path to the folder where the log will be stored.
        .PARAMETER Bias
            Set timezone Bias to ensure timestamps are accurate. This defaults to the local machines bias, but one can be provided. It can be
            helperful to gather the bias once, and store it in a variable that is passed to this parameter as part of a splat, or $PSDefaultParameterValues
        .PARAMETER MaxLogFileSize
            Maximum size of log file before it rolls over. Set to 0 to disable log rotation. Defaults to 5MB
        .PARAMETER LogsToKeep
            Maximum number of rotated log files to keep. Set to 0 for unlimited rotated log files. Defaults to 0.
        .EXAMPLE
            C:\PS> Write-CCMLogEntry -Value 'Testing Function' -Component 'Test Script' -FileName 'LogTest.Log' -Folder 'c:\temp'
                Write out 'Testing Function' to the c:\temp\LogTest.Log file in a CMTrace format, noting 'Test Script' as the component.
        .NOTES
            FileName:    Write-CCMLogEntry.ps1
            Author:      Cody Mathis, Adam Cook
            Contact:     @CodyMathis123, @codaamok
            Created:     2020-01-23
            Updated:     2020-01-23
    #>
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Message', 'ToLog')]
        [string[]]$Value,
        [parameter(Mandatory = $false)]
        [ValidateSet(1, 2, 3)]
        [int]$Severity = 1,
        [parameter(Mandatory = $false)]
        [string]$Component = [string]::Format("PatchMyPC-{0}:{1}", $Purpose, $($MyInvocation.ScriptLineNumber)),
        [parameter(Mandatory = $true)]
        [string]$FileName,
        [parameter(Mandatory = $true)]
        [string]$Folder,
        [parameter(Mandatory = $false)]
        [int]$Bias = [System.DateTimeOffset]::Now.Offset.TotalMinutes,
        [parameter(Mandatory = $false)]
        [int]$MaxLogFileSize = 5MB,
        [parameter(Mandatory = $false)]
        [int]$LogsToKeep = 0
    )
    begin {
        # Determine log file location
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName

        #region log rollover check if $MaxLogFileSize is greater than 0
        switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
            $true {
                #region rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                    $true {
                        # Get log file name without extension
                        $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))

                        # Get already rolled over logs
                        $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File

                        # Sort them numerically (so the oldest is first in the list)
                        $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore

                        foreach ($Log in $AllLogs) {
                            # Get log number
                            $LogFileNumber = [int][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                            switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                $true {
                                    # Delete log if it breaches $LogsToKeep parameter value
                                    [System.IO.File]::Delete("$($Folder)\$($Log)")
                                }
                                $false {
                                    # Rename log to +1
                                    $NewFileName = $Log -replace "_([0-9]+)\.lo_$", "_$($LogFileNumber+1).lo_"
                                    [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)
                                }
                            }
                        }

                        # Copy main log to _1.lo_
                        [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)

                        # Blank the main log
                        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                        $StreamWriter.Close()
                    }
                }
                #endregion rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
            }
        }
        #endregion log rollover check if $MaxLogFileSize is greater than 0

        # Construct date for log entry
        $Date = (Get-Date -Format 'MM-dd-yyyy')

        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    }
    process {
        foreach ($MSG in $Value) {
            #region construct time stamp for log entry based on $Bias and current time
            $Time = switch -regex ($Bias) {
                '-' {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                }
                Default {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                }
            }
            #endregion construct time stamp for log entry based on $Bias and current time

            #region construct the log entry according to CMTrace format
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $Severity, $PID)
            #endregion construct the log entry according to CMTrace format

            #region add value to log file
            try {
                $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()
            }
            catch [System.Exception] {
                try {
                    $LogText | Out-File -FilePath $LogFilePath -Append -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
                }
            }
            #endregion add value to log file
        }
    }
}

Function Get-PMPVersionFromString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$stringVar
    )
    $ExtractedVersion = [string]::Empty
    if ($stringVar -match "\d+\.\d+(\.\d+)?(\.\d+)?") {
        $ExtractedVersion = $Matches[0]
    }
    Write-Verbose "Extracted version $ExtractedVersion from $stringVar"
    return $ExtractedVersion
}

Function ConvertTo-PMPVersion {
    [CmdletBinding()]
    param(
        [string]$versionString
    )
    try {
        switch (($versionString.ToCharArray() | Where-Object { $_ -eq '.' }).Count) {
            0 {
                $versionString += '.0' * 3
            }
            1 {
                $versionString += '.0.0'
            }
            2 {
                $versionString += '.0'
            }
        }

        return Get-PMPParsedVersion -versionString $versionString
    }
    catch {
        $splitVersionString = $versionString.Split([char]46)
        $fixedVersionStringArray = foreach ($Component in $splitVersionString) {
            try {
                [int]$Component
            }
            catch {
                Write-Verbose "Failed to cast part of the version to an integer. Defaulting to max 32 bit signed integer. [Original Value: $Component]"
                [int]::MaxValue
            }
        }

        try {
            Get-PMPParsedVersion -versionString $([string]::Join([char]46, $fixedVersionStringArray))
        }
        catch {
            return [System.Version]('0.0.0.0')
        }
    }
}

Function Get-PMPParsedVersion {
    [CmdletBinding()]
    param(
        [string]$versionString
    )
    [System.Version]$version = $versionString
    $major = if ($version.Major -eq -1) {
        0
    }
    else {
        $version.Major
    }
    $minor = if ($version.Minor -eq -1) {
        0
    }
    else {
        $version.Minor
    }
    $build = if ($version.Build -eq -1) {
        0
    }
    else {
        $version.Build
    }
    $revision = if ($version.Revision -eq -1) {
        0
    }
    else {
        $version.Revision
    }

    return [System.Version]("$major.$minor.$build.$revision")
}

Function Compare-PMPVersion {
    param(
        [string]$CurrentVersion,
        [string]$TargetVersion,
        [ValidateSet('Requirement', 'Detection')]
        [string]$Purpose
    )

    [System.Version]$version1 = ConvertTo-PMPVersion($CurrentVersion)
    [System.Version]$version2 = ConvertTo-PMPVersion($TargetVersion)

    switch ($Purpose) {
        Requirement {
            $Result = $version1.CompareTo($version2) -lt 0
        }
        Detection {
            $Result = $version1.CompareTo($version2) -ge 0
        }
    }

    Write-Verbose "Result of comparing Current Version $CurrentVersion to Target Version $TargetVersion for the purpose of $Purpose rule = $Result"

    return $Result
}

Function Get-PMPInstalledSoftwares {
    param(
        [ValidateSet('Both', 'x86', 'x64')]
        [string]$Architecture,
        [Parameter(Mandatory = $false)]
        [ValidateSet('HKLM', 'HKCU')]
        [string[]]$HivesToSearch
    )
    $PathsToSearch = switch -regex ($Architecture) {
        'Both|x86' {
            # IntPtr will be 4 on a 32 bit system, so this add Wow6432Node if script running on 64 bit system
            if (-not ([IntPtr]::Size -eq 4)) {
                'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }
            # If not running on a 64 bit system then we will search for 32 bit apps in the normal software node, non-Wow6432
            else {
                'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }
        }
        'Both|x64' {
            # If we are searching for a 64 bit application then we will only search the normal software node, non-Wow6432
            if (-not ([IntPtr]::Size -eq 4)) {
                'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }
        }
    }


    $FullPaths = foreach ($PathFragment in $PathsToSearch) {
        switch ($HivesToSearch) {
            'HKLM' {
                [string]::Format('registry::HKEY_LOCAL_MACHINE\{0}', $PathFragment)

            }
            'HKCU' {
                [string]::Format('registry::HKEY_CURRENT_USER\{0}', $PathFragment)
            }
        }
    }

    Write-Verbose "Will search the following registry paths based on [Architecture = $Architecture] [HivesToSearch = $HivesToSearch]"
    foreach ($RegPath in $FullPaths) {
        Write-Verbose $RegPath
    }

    $propertyNames = 'DisplayName', 'DisplayVersion', 'PSChildName', 'Publisher', 'InstallDate'

    $AllFoundObjects = Get-ItemProperty -Path $FullPaths -Name $propertyNames -ErrorAction SilentlyContinue

    foreach ($Result in $AllFoundObjects) {
        if (-not [string]::IsNullOrEmpty($Result.DisplayName)) {
            $Result | Select-Object -Property $propertyNames
        }
    }
}

function Test-PMPInstallerType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        [Parameter(Mandatory = $false)]
        [ValidateSet('EXE', 'MSI', 'ANY')]
        [string]$InstallerType = 'ANY'
    )
    switch ($InstallerType) {
        MSI {
            return $KeyName -as [guid] -is [guid]
        }
        EXE {
            return -not ($KeyName -as [guid] -is [guid])
        }
        ANY {
            return $true
        }
    }
}

function Test-PMPRegKeyAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RegKeyDetection
    )

    # $RegKeyDetection = @{
    #     @{
    #         'SOFTWARE\Google\Update\ClientState\{8A69D345-D564-463C-AFF1-A69D9E530F96}' = 'ap'
    #     } = @{
    #         Value       = 'x64'
    #         WOW6432Node = $true
    #         Operator    = '-match'
    #     };
    #     @{
    #         'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{018CF00D-E79A-4F40-B2B6-EA76AACF88DC}' = 'InstallDate'
    #     } = @{
    #         Value       = '1'
    #         WOW6432Node = $false
    #         Operator    = '-ge'
    #     };
    # }
    foreach ($RegKey in $RegKeyDetection.GetEnumerator()) {
        $InitialKey = $RegKey.Key.Keys
        $InitialKeyString = $InitialKey | Out-String
        $PropertyToCheck = $RegKey.Key[$InitialKey]
        $ExpectedValue = $RegKey.Value.Value
        $WOW6432Node = $RegKey.Value.WOW6432Node
        $Operator = $RegKey.Value.Operator

        switch ($WOW6432Node) {
            $true {
                if ($InitialKeyString.StartsWith("SOFTWARE\", [StringComparison]::OrdinalIgnoreCase)) {
                    $resolvedPath = [string]::Concat("registry::HKEY_LOCAL_MACHINE\",
                        "$(if([IntPtr]::Size-eq4){'SOFTWARE'}else{'SOFTWARE\wow6432node'})",
                        $InitialKeyString.Substring(8))
                }
                else {
                    $resolvedPath = [string]::Concat("registry::HKEY_LOCAL_MACHINE\", $InitialKey)
                }
            }
            $false {
                $resolvedPath = [string]::Concat("registry::HKEY_LOCAL_MACHINE\", $InitialKey)
            }
        }

        if (-not [scriptblock]::Create("'$((Get-ItemProperty -Path $resolvedPath.Trim() -Name $PropertyToCheck -ErrorAction SilentlyContinue).$PropertyToCheck)' $Operator '$ExpectedValue'").Invoke()) {
            return $false
        }
    }

    return $true
}

Function Test-PMPAppMeetsCondition {
    param(
        [string]$ApplicationName,
        [string]$ApplicationNameExclusion,
        [string]$ApplicationVersion,
        [string]$ApplicationVersionFilter,
        [string]$MSIProductCode,
        [ValidateSet('Both', 'x86', 'x64')]
        [string]$Architecture,
        [ValidateSet('Requirement', 'Detection')]
        [string]$Purpose,
        [Parameter(Mandatory = $false)]
        [ValidateSet('HKLM', 'HKCU')]
        [string[]]$HivesToSearch,
        [Parameter(Mandatory = $false)]
        [ValidateSet('EXE', 'MSI', 'ANY')]
        [string]$InstallerType = 'Any',
        [Parameter(Mandatory = $false)]
        [hashtable]$RegKeyDetection = @{}
    )

    $AllInstalledSoftware = Get-PMPInstalledSoftwares -Architecture $Architecture -HivesToSearch $HivesToSearch
    $MatchingInstalledSoftware = foreach ($InstalledSoftware in $AllInstalledSoftware) {
        if ([string]::IsNullOrEmpty($InstalledSoftware.DisplayVersion)) {
            $DisplayVersion = $InstalledSoftware.DisplayVersion
        }
        else {
            $DisplayVersion = Get-PMPVersionFromString -stringVar $InstalledSoftware.DisplayVersion.ToString()
        }
        $version = Get-PMPVersionFromString -stringVar $InstalledSoftware.DisplayName
        if (-not [string]::IsNullOrEmpty($ApplicationNameExclusion) -and $InstalledSoftware.DisplayName -like $ApplicationNameExclusion) {
            Write-CCMLogEntry -Message "Ignoring $($InstalledSoftware.DisplayName) because it matches our exclusion name $ApplicationNameExclusion" @LogParams -Severity 2
            continue
        }
        elseif ($InstalledSoftware.PSChildname -eq $MSIProductCode -and (Test-PMPInstallerType -KeyName $InstalledSoftware.PSChildname -InstallerType $InstallerType)) {
            if ($DisplayVersion -notlike $ApplicationVersionFilter) {
                Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode. It does not match the ApplicationVersionFilter of $ApplicationVersionFilter" @LogParams -Severity 2
            }
            else {
                if ($RegKeyDetection.Keys.Count -gt 0) {
                    if (Test-PMPRegKeyAction -RegKeyDetection $RegKeyDetection) {
                        Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode"
                        $InstalledSoftware
                    }
                    else {
                        Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because a provided RegKeyDetection did not pass" @LogParams -Severity 2
                    }
                }
                else {
                    Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode"
                    $InstalledSoftware
                }
            }
        }
        elseif ($InstalledSoftware.DisplayName -like $ApplicationName) {
            if (Test-PMPInstallerType -KeyName $InstalledSoftware.PSChildname -InstallerType $InstallerType) {
                if ($null -ne $InstalledSoftware.DisplayVersion -and ((Compare-PMPVersion -CurrentVersion $DisplayVersion -TargetVersion $ApplicationVersion -Purpose $Purpose) -or ($null -eq $InstalledSoftware.DisplayVersion -and (Compare-PMPVersion -CurrentVersion $version -TargetVersion $ApplicationVersion -Purpose $Purpose)))) {
                    if ($DisplayVersion -notlike $ApplicationVersionFilter) {
                        Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version. It does not match the ApplicationVersionFilter of $ApplicationVersionFilter" @LogParams -Severity 2
                    }
                    else {
                        if ($RegKeyDetection.Keys.Count -gt 0) {
                            if (Test-PMPRegKeyAction -RegKeyDetection $RegKeyDetection) {
                                Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version"
                                $InstalledSoftware
                            }
                            else {
                                Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because a provided RegKeyDetection did not pass" @LogParams -Severity 2
                            }
                        }
                        else {
                            Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version"
                            $InstalledSoftware
                        }
                    }
                }
            }
            else {
                Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because the key name [$($InstalledSoftware.PSChildName)] does not meet the installer type condition [Installer Type: $InstallerType]" @LogParams -Severity 3
            }
        }

    }
    If ($null -eq $MatchingInstalledSoftware) {
        # No match found for DisplayName and DisplayVersion check
                Write-CCMLogEntry -Message "No valid software found for $($ApplicationName) with version $($ApplicationVersion) meeting $Purpose rules" @LogParams -Severity 2
        Return $false
    }
    Else {
        foreach ($Software in $MatchingInstalledSoftware) {
            # Found match
            Write-CCMLogEntry -Message "Found $($Software.DisplayName) version $($Software.DisplayVersion) installed on $($Software.InstallDate)" @LogParams
        }
        Return $true
    }
}
#endregion functions

#region define logging params
$LogParams = @{
    FileName       = $LogFileName
    Folder         = Get-PMPLogPath
    Bias           = [System.DateTimeOffset]::Now.Offset.TotalMinutes
    MaxLogFileSize = 2mb
    LogsToKeep     = 1
}
#endregion define logging params

#region proxy function for logging
# #Write-Verbose
$WriteVerboseMetadata = New-Object System.Management.Automation.CommandMetadata (Get-Command Write-Verbose)
$WriteVerboseBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($WriteVerboseMetadata)
$WriteVerboseParams = [System.Management.Automation.ProxyCommand]::GetParamBlock($WriteVerboseMetadata)
$WriteVerboseWrapped = { Microsoft.PowerShell.Utility\Write-Verbose @PSBoundParameters; switch ($VerbosePreference) {
        'Continue' {
            Write-CCMLogEntry -Message $Message @LogParams
        }
    } }
${Function:Write-Verbose} = [string]::Format('{0}param({1}) {2}', $WriteVerboseBinding, $WriteVerboseParams, $WriteVerboseWrapped)
#endregion proxy function for logging

# Main program
Write-CCMLogEntry -Message "*** Starting $Purpose script for $AppToSearch $(if(-not [string]::IsNullOrEmpty($AppToAvoid)) {"except $AppToAvoid"}) with version $ApplicationVersionToSearch" @LogParams
Write-CCMLogEntry -Message "$Purpose script version $ScriptVersion" @LogParams
Write-CCMLogEntry -Message "Running as $env:username $(if(Test-IsRunningAsAdministrator) {"[Administrator]"} Else {"[Not Administrator]"}) on $env:computername" @LogParams

$TestInstalledSplat = @{
    ApplicationName          = $AppToSearch
    ApplicationNameExclusion = $AppToAvoid
    ApplicationVersion       = $ApplicationVersionToSearch
    MSIProductCode           = $AppMSICodeToSearch
    Architecture             = $Architecture
    Purpose                  = $Purpose
    HivesToSearch            = $HivesToSearch
    ApplicationVersionFilter = $ApplicationVersionFilter
    InstallerType            = $InstallerType
    RegKeyDetection          = $RegKeyDetection
}
$detectionResult = Test-PMPAppMeetsCondition @TestInstalledSplat

if ($detectionResult) {
    $Result = switch ($Purpose) {
        Detection {
            Write-Output 'Installed'
        }
        Requirement {
            Write-Output 'Applicable'
        }
    }
    Write-CCMLogEntry -Message  "Result of script for checking $Purpose`: $Result" @LogParams
    Write-Output $Result
}

Write-CCMLogEntry -Message "*** Ending $Purpose script for $AppToSearch $(if(-not [string]::IsNullOrEmpty($AppToAvoid)) {"except $AppToAvoid"}) with version $ApplicationVersionToSearch" @LogParams
Exit 0

# SIG # Begin signature block
# MIIbsgYJKoZIhvcNAQcCoIIbozCCG58CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBXaUmEmrmLV2+c
# SlceUj7IWnffGZwZVR0cUjGTR/wOxaCCFfgwggLtMIIB1aADAgECAhBJrTsObzDz
# lkGpPIQBnMDbMA0GCSqGSIb3DQEBCwUAMCYxJDAiBgNVBAMTG1dTVVMgUHVibGlz
# aGVycyBTZWxmLXNpZ25lZDAeFw0yMDA0MDUxMzI2MjlaFw0yNTA0MDQxMzI2Mjla
# MCYxJDAiBgNVBAMTG1dTVVMgUHVibGlzaGVycyBTZWxmLXNpZ25lZDCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBAL5HyuvqBYKMnbIBi4DruCehrMqoJPa5
# rVpp7g3czaSs9+2FXwtrdIlZDhXw0PFQRRgVDf3s8al15RUFjg46aePHpfSSTMOO
# 0zcYxQEqht0DsKeWR6rjM6ew+q3vnntsLEUUkYCxY/9Kf6AshBKjq6c8wOgDid0b
# kM2/a0M42ZlOvBdyiYY1bkHXjfoII8Yur9vsPNgl1G2+qPZlj4tDsCDHxhsuGkF9
# zS9xMCnDod8BzYx9kzryxCvrlMff11hho3XeyQiOY+VartUpzirllAUtBTH+RoAc
# pczDe4RL2vbRn+4yKfXwGPLy2ledScxwI4oUM1qr9JP680P5LUpZpB0CAwEAAaMX
# MBUwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDQYJKoZIhvcNAQELBQADggEBAIrKR6Wz
# ty/ewMm7iL11kaKQUX/dCi4c3WYtt1XdUraUp3LRWTjjzRXcZY+yQm9w/kh16w3q
# XXv426/KTA2jQwEyc5xdaed3Tluy8FeZUnwPAQDwMfy55OMaG+X+e1+YtkWf/LS5
# oKRQ5s+N+zxIaU/dkNGGawskuDZJp3xr1wc6Q+UyPQ3wX3oZQQz+Mcsu2yKA9spz
# wJD0MfWUcvS4Ppnt6nT1CImRXipO1UDt+DI2HGEtJz1VZnWa3pHp3qNqgUhHR5hd
# e2YctAkZ6YedJpTvRhI3S0OEX6Co79KpCaO1cBNGraDGWd7I2RVvUGq6uTkNKNPQ
# 0bffq/scBCj+RiQwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqG
# SIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFz
# c3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTla
# MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9v
# dCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8
# MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauy
# efLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34Lz
# B4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+x
# embud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhA
# kHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1Lyu
# GwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2
# PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37A
# lLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD7
# 6GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/
# ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXA
# j6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTAD
# AQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF
# 66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEE
# bTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYB
# BQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAI
# MAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979X
# B72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4k
# vFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU
# 53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pc
# VIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5v
# Iy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwggau
# MIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAe
# Fw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9Ge
# TKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0
# hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZl
# jZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAsh
# aG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVY
# TXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1
# biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCir
# c0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+
# DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA
# +bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42Pg
# puE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzS
# M7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
# uhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6
# mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsG
# AQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
# MEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAE
# GTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1Z
# jsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8d
# B+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVp
# P0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp8
# 76i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2
# nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3
# ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQ
# txMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc
# 4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+Y
# AN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZ
# vAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQr
# H4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGwDCCBKigAwIBAgIQDE1p
# ckuU+jwqSj0pB4A9WjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQg
# RzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIyMDkyMTAwMDAw
# MFoXDTMzMTEyMTIzNTk1OVowRjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lD
# ZXJ0MSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMiAtIDIwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDP7KUmOsap8mu7jcENmtuh6BSFdDMa
# JqzQHFUeHjZtvJJVDGH0nQl3PRWWCC9rZKT9BoMW15GSOBwxApb7crGXOlWvM+xh
# iummKNuQY1y9iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpkU7sqFudQSLuIaQyIxvG+
# 4C99O7HKU41Agx7ny3JJKB5MgB6FVueF7fJhvKo6B332q27lZt3iXPUv7Y3UTZWE
# aOOAy2p50dIQkUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyVR4aF
# eT4MXmaMGgokvpyq0py2909ueMQoP6McD1AGN7oI2TWmtR7aeFgdOej4TJEQln5N
# 4d3CraV++C0bH+wrRhijGfY59/XBT3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq5Xwx
# 5/PCUsTmFntafqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk+lbP
# 4PQK5hRtZHi7mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl5S4p
# kKa3YWT62SBsGFFguqaBDwklU/G/O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7ucxn
# EweawXjtxojIsG4yeccLWYONxu71LHx7jstkifGxxLjnU15fVdJ9GSlZA076XepF
# cxyEftfO4tQ6dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshv
# MB0GA1UdDgQWBBRiit7QYfyPMRTtlwvNPSqUFN9SnDBaBgNVHR8EUzBRME+gTaBL
# hklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0
# MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAC
# hkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRS
# U0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQBVqioa80bzeFc3MPx140/WhSPx/PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4iGNV
# CUY5APxp1MqbKfujP8DJAJsTHbCYidx48s18hc1Tna9i4mFmoxQqRYdKmEIrUPwb
# tZ4IMAn65C3XCYl5+QnmiM59G7hqopvBU2AJ6KO4ndetHxy47JhB8PYOgPvk/9+d
# EKfrALpfSo8aOlK06r8JSRU1NlmaD1TSsht/fl4JrXZUinRtytIFZyt26/+YsiaV
# OBmIRBTlClmia+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSvXQJT657inuTTH4YBZJwA
# wuladHUNPeF5iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85dNdRZPkOaGK7DycvD+5sT
# X2q1x+DzBcNZ3ydiK95ByVO5/zQQZ/YmMph7/lxClIGUgp2sCovGSxVK05iQRWAz
# gOAj3vgDpPZFR+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+bvdgc
# mlHEL5r2X6cnl7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJGgV8unG1TnqZbPTontRa
# mMifv427GFxD9dAq6OJi7ngE273R+1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/Otrl
# 5fbmm9x+LMz/F0xNAKLY1gEOuIvu5uByVYksJxlh9ncBjDGCBRAwggUMAgEBMDow
# JjEkMCIGA1UEAxMbV1NVUyBQdWJsaXNoZXJzIFNlbGYtc2lnbmVkAhBJrTsObzDz
# lkGpPIQBnMDbMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEhPjhU2uqNfbLgir4AbXILW
# QH6yEoFQw3E0fg27lwtKMA0GCSqGSIb3DQEBAQUABIIBACo+NzyMV4EPqWcZeuRl
# IM84fvRHST+OpGpKMIMluSfWMkSjzdJkEpo8R74wjXym1CgSZqe8SN3sXXomSg24
# Hf9RG859D/aFEHWyXWkZ+/eit661bMleXofkRWEajjd3Y4VDVt37R8z9DBiluT8H
# jt1d3U1JEsFLGXVoV51gvSJU4K3c1IM9lCAnCkk0urwgSlAXaFX0jxESGm2Gx1wu
# DpodWHbyWzs11+cAg7gpiOs+x+2n1evIcdu/XDPbf9m44W80faHSLo1c167fDask
# qb9SrLQI+6DsH3FmnxeMBRAHdZg1+YuubdBg15JFik9S7uYxDNA/w0F6mXr/E3MA
# 94ChggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEwdzBjMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRy
# dXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAMTWlyS5T6
# PCpKPSkHgD1aMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMjIxMTMwMDIyOTQ3WjAvBgkqhkiG9w0BCQQx
# IgQgi6lhr8yAPcqoUQ/yfNh48Jgzp2ykaBoe8CPg2c/PxB4wDQYJKoZIhvcNAQEB
# BQAEggIAoA7G1JHOa15soVqp0+aRrQ6GF34SM+suLYvOZSGq0uOyaj3Xr4PSpKuj
# ljCSyH2soH3SivHzrNvi4K0uDRNKh4TQx/XQ4b2Uc7V5cCC6rtWlVuSOBNiAbuDA
# i+x/Llk2ksPX5nmPVmo3pgzlp9PhEE4JSJBEcgSg/t55NWayUaNDf2PhrJ9I40n6
# F/Ip1BwF8Y4KRzOquvluF24CVWqw0Qdt8sowgPRtY+sKRq3+JjZsaxssHd45Ihg1
# 4/bGb1lHE5oMxMhIw81RnlMJqKaMLP9PiEc7lvGb+98IsF6w3j2R7lSg+9m94+NV
# bRbN0dwcHfzTPt08TylVPLdl3p/F0rCSNEoZN6a/a7uPjgn3fFEsZYn31M6v3pWB
# 1F5nw/7fba/BHxE9vx6SF6mWzEM7BXzv5Zju0vcC1tm5KJ9gK0h7mzb4Ya+Nvhal
# tQfzdznecCLByLYfn/SgbOr45JJgrro6x4x/gwGSJVLmzNxrA4DqFu8UgoxVL9Kj
# p5/s04ZdOCjnB7XzjVVY+NzLKTIbJNr02eup3/oq/1L0ynvRWCdJjxtF5tNVSaEO
# uRcoajP74dohgiqd4zc8LLsOgu39fPNls928NOJp/WL2SBE9smc+/AP+TCIbUn9y
# O9bgPmHEhVO00rZ/K82qAusu7BNj/5OoIMBLCE3/2t729I6PHuY=
# SIG # End signature block
