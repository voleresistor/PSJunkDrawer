<#
    Solution: OSD
    Purpose: Clean up unnecessary files from extracted driver packages
    Version:1.1 - 04/11/17
                - Remove $RootFolder Variable
                - Shorten SourcePath and DestPath to Source and Dest
                - Add comments
            1.0 - 02/23/17

    Author: Andrew Ogden
    Email: andrew.ogden@dxpe.com
#>

param
(
    [string]$SourceFolder,
    [string]$DestFolder,
    # I have found no clear source stating what files should and shouldn't be present here.
    # TODO: Parse *.inf files for dependent files and keep only those
    [array]$FileExtensions = @('*.dll','*.ini','*.sys','*.cat','*.inf','*.cab') # ,'*.bin','*.oem','*.cpa','*.vp'
)

# Get list of files in source
$SaveFiles = Get-ChildItem -Path "$SourceFolder" -Include $FileExtensions -Recurse

# Format Source folder for regexp
$SourceRegExp = $SourceFolder -replace ('\\', '\\')

# Create destination folder if it doesn't exist
if (!(Test-Path -Path "$DestFolder" -ErrorAction SilentlyContinue))
{
    New-Item -Path "$DestFolder" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

# Copy only matching files and increment file size
$DestSize = 0
foreach ($file in $SaveFiles)
{
    $DestSize += $($file.Length)
    Write-Host $($file.FullName -replace ($SourceRegExp, $DestFolder))

    # Create subfolders in source to maintain organization
    if (!(Test-Path -Path $($file.Directory -replace ($SourceRegExp, $DestFolder)) -ErrorAction SilentlyContinue))
    {
        New-Item -Path $($file.Directory -replace ($SourceRegExp, $DestFolder)) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Copy files to new path
    Copy-Item -Path $($file.FullName) -Destination $($file.FullName -replace ($SourceRegExp, $DestFolder)) -Force
}

# Display total size of copies files
Write-Host "New folder size: $($DestSize / 1mb)"