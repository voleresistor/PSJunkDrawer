#region Invoke-RoboCopy
function Invoke-Robocopy
{
    <#
    .Synopsis
    ***PENDING REWRITE/DELETION - AO 12/01/17***
    PowerShell wrapper for RoboCopy.
    
    .Description
    Provides switches and simple syntax including Intellisense to simplify PowerShell usage.
    
    .Parameter Source
    The source location.
    
    .Parameter Destination
    The destination location.
    
    .Parameter Filter
    A simple filter for the files/folders within the source. Can be used with wildcards.
    
    .Parameter LogLocation
    The path and filename where robocopy logs should be written.

    .Parameter Tee
    Output to console window, as well as the log file.
    
    .Parameter Recurse
    Copy subdirectories, including Empty ones.
    
    .Parameter Open
    Open destination directory after transfer is completed.
    
    .Parameter ExcludeOld
    Exclude files and folders that older than those in the destination.
    
    .Parameter MultiThread
    Run multiple concurrent transfer threads.
    
    .Parameter CopyAll
    Copy all file and folder attributes.
    
    .Parameter RunHours
    Hour range in which transfers are to be performed.
    
    .Parameter PerFile
    Check run hours between each individual file.
    
    .Parameter Retry
    Number of time to retry a failed file copy before skipping it.
    
    .Parameter Mirror
    Mirror a directory tree.
    
    .Parameter Move
    Delete files from the source.
    
    .Parameter List
    Only list files in source directory. Do not change, copy, delete, or timestamp anything.
    
    .Parameter Create
    Create directory structure and zero length files in destination.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user
    
    Copy all files from the source folder to the destination folder.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -Filter *work*
    
    Copy all files with "work" in the name from the source to the destination.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -RunHour 1900-0600 -PerFile
    
    Copy all files between 7:00pm and 6:00am. Check time between every file.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -ExcludeOld
    
    Only copy files that are new or have changed.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -List
    
    List files that would be copied.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -LogLocation C:\Temp\transfer.log -Tee
    
    Copy files while writing a log. Also output log to console.
    #>
    param 
    (
        [String]
        [Parameter(Mandatory)]
        $Source,
        
        [String]
        [Parameter(Mandatory)]
        $Destination,
        
        [String]
        $Filter = '*',
        
        [String]
        $LogLocation,
        
        [Switch]
        $Tee,
        
        [Switch]
        $Recurse,
        
        [Switch]
        $Open,
        
        [Switch]
        $ExcludeOld,
        
        [int]
        $MultiThread,
        
        [Switch]
        $CopyAll,
        
        [String]
        $RunHours,
        
        [Switch]
        $PerFile,
        
        [Int]
        $Retry,
        
        [Switch]
        $Mirror,
        
        [Switch]
        $Move,
        
        [Switch]
        $List,
        
        [Switch]
        $Create
    )
    
    #Define null variables
    $DoRecurse = $null
    $DoLogging = $null
    $DoTee = $null
    $DoExclude = $null
    $DoMultithread = $null
    $DoCopyAll = $null
    $DoRunHour = $null
    $DoPerFile = $null
    $DoCreate = $null
    $DoList = $null
    $DoMove = $null
    $DoMirror = $null
    $Retry = $null
    
    #**************************
    # Set various switches here
    
    # Recurse, keeping empty directories
    if ($Recurse)
    {
        $DoRecurse = '/E '
    }
    
    #Exclude old files
    if ($ExcludeOld)
    {
        $DoExclude = '/XO '
    }
    
    #Logging
    if ($LogLocation)
    {
        $DoLogging = "/LOG:`"$LogLocation`" "
    }
    
    #Log Teeing
    if ($Tee)
    {
        $DoTee = '/TEE '
    }
    
    #Multithreading
    if ($MultiThread)
    {
        $DoMultithread = "/MT:$MultiThread "
    }
    
    #Copy all settings
    if ($CopyAll)
    {
        $DoCopyAll = '/COPYALL '
    }
    
    #Run hours
    if ($RunHours)
    {
        $DoRunHour = "/RH:`"$RunHours`" "
    }
    
    #Check run hours per file
    if ($PerFile)
    {
        $DoPerFile = '/PF '
    }
    
    #Create
    if ($Create)
    {
        $DoCreate = '/CREATE '
    }
    
    #List
    if ($List)
    {
        $DoList = '/L '
    }
    
    #Move
    if ($Move)
    {
        $DoMove = '/MOVE '
    }

    #Mirror
    if ($Mirror)
    {
        $DoMirror = '/MIR '
    }
    
    #**************************
    
    #Populate arguments string
    $RoboCopyArgs = '"$Source" '
    $RoboCopyArgs += '"$Destination" '
    $RoboCopyArgs += '"$Filter" '
    $RoboCopyArgs += '$DoRecurse '
    $RoboCopyArgs += '$DoLogging '
    $RoboCopyArgs += '$DoTee '
    $RoboCopyArgs += '$DoExclude '
    $RoboCopyArgs += '$DoMultithread '
    $RoboCopyArgs += '$DoCopyAll '
    $RoboCopyArgs += '$DoRunHour '
    $RoboCopyArgs += '$DoPerFile '
    $RoboCopyArgs += '$DoCreate '
    $RoboCopyArgs += '$DoList '
    $RoboCopyArgs += '$DoMove '
    $RoboCopyArgs += '$DoMirror '
    $RoboCopyArgs += '/R:$Retry'
    
    #Expand variable encapsulated in single quotes
    $RoboCopyArgs = $ExecutionContext.InvokeCommand.ExpandString($RoboCopyArgs)
    
    #Begin the robocopy job
    Start-Process -FilePath 'robocopy.exe' -ArgumentList $RoboCopyArgs -NoNewWindow -Wait
       
    if ($Open)
    {
        explorer.exe $Destination
    }
}
#endregion
