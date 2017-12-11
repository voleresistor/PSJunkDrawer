function Write-Log
{
    <#
    .SYNOPSIS
    Generate log entries that are compatible with CMTrace.
    
    .PARAMETER LogPath
    The path to the log file.
    
    .PARAMETER Message
    The message to be logged.
    
    .PARAMETER TimeStamp
    The time the message was logged.
    
    .PARAMETER Datestamp
    The date the message was logged.
    
    .PARAMETER Component
    The system or function generating the log entry.
    
    .PARAMETER Context
    The context under which the log entry was generated.
    
    .PARAMETER Type
    The type of log being entered.
    
    .PARAMETER Thread
    A thread or process ID.
    
    .PARAMETER File
    The file that was running when the log was generated.
    
    .EXAMPLE
    Write-Log -LogPath c:\temp\deployment.log -Message "The process completed successfully." -TimeStamp 13:01:15.047394 -DateStamp 12/11/17

    Write a log entry to c:\temp\deployment.log.
    #>
    [CmdletBinding()]
    param
    (
        [string]$LogPath,
        [string]$Message,
        [string]$TimeStamp,
        [string]$DateStamp,
        [string]$Component,
        [string]$Context,
        [string]$Type,
        [string]$Thread,
        [string]$File
    )

    # Formatted to be easily parsed by cmtrace.exe
    $LogMessage = "<![LOG[$Message]LOG]!><time=`"$TimeStamp`" date=`"$DateStamp`" component=`"$Component`" context=`"$Context`" type=`"$Type`" thread=`"$Thread`" file=`"$File`">"

    # Introduce some extremely simple error handling
    try
    {
        Add-Content -Value $LogMessage -Path $LogPath -ErrorAction Stop
    }
    catch
    {
        Write-Verbose -Message $_.Exception.Message
    }
}