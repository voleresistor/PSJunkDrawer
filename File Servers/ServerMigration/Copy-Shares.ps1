param
(
    [Parameter(Mandatory=$true)]
    [string]$InputCsv,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\temp\Copy-Netapp\RoboCopy"
)

<#
    .Synopsis
    Copy data from a list of shares.
    
    .Description
    Takes a list of source and destination shares from an input CSV and copies all files from the source to the destination.
    
    .Parameter InputCsv
    The CSV file containing settings for this script.

    .Parameter LogPath
    The location and name of the logfile.
    
    .Example
    Copy-Shares.ps1 -InputCsv c:\temp\migration.csv
    
    Copies all shares listed in the input CSV to the corresponding destination server.
#>

# Initialize log path
if (!(Test-Path -Path $LogPath))
{
    New-Item -Path $LogPath -Force -ItemType Directory | Out-Null
}

#Import CSV file
$CsvFile = Import-Csv -Path $InputCsv -Delimiter ','

foreach ($entry in $CsvFile)
{
    $Destination = "\\" + $($entry.PrimaryServer) + "\" + $($entry.ParentFolder) + "\" + $($entry.ShareName)
    Start-Process -FilePath "$env:windir\System32\robocopy.exe" -ArgumentList "`"$($entry.SourcePath)`" `"$Destination`" /E /XO /R:5 /W:5 /COPY:DATSO /DCOPY:DAT /LOG+:`"$LogPath\$($entry.ShareName).log`"" -Wait -NoNewWindow
}