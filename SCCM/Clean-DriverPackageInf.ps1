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
    [string]$DestFolder
)

# CopyFiles function
function CopyFiles
{
    param
    (
        [int]$StartLine, # First line of SourceDisksFiles section
        [array]$InfSource, # Text of the INF file
        [string]$Source, # Directory the INF lives in
        [string]$Dest, # New folder to copy files to
        [string]$Class # Subfolder
    )

    $j = $StartLine
    while ($InfSource[$j] -notlike '')
    {
        # Create new folder if necessary
        if (!(Test-Path -Path "$Dest\$Class"))
        {
            New-Item -Path "$Dest\$Class" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # If subfolders exist, we must deal with them
        if (($InfSource[$j] -split(','))[1])
        {
            if (!(Test-Path -Path "$Dest\$Class\$($($InfSource[$j] -split(','))[1])"))
            {
                New-Item -Path "$Dest\$Class\$($($InfSource[$j] -split(','))[1])" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            }

            #Copy file
            #Write-Host "Source: $Source\$($($InfSource[$j] -split(','))[1])\$($($InfSource[$j] -split(' '))[0])"
            #Write-Host "Dest: $Dest\$Class\$($($InfSource[$j] -split(','))[1])"
            Copy-Item -Path "$Source\$($($InfSource[$j] -split(','))[1])\$($($InfSource[$j] -split(' '))[0])" -Destination "$Dest\$Class\$($($InfSource[$j] -split(','))[1])" -Force
        }
        else # If no subfolder for this entry just do the copy
        {
            #Copy file
            #Write-Host "Source: $Source\$($($InfSource[$j] -split(' '))[0])"
            #Write-Host "Dest: $Dest\$Class"
            Copy-Item -Path "$Source\$($($InfSource[$j] -split(' '))[0])" -Destination "$Dest\$Class" -Force
        }

        #Increment
        $j++
    }
}

# Get list of files in source
$InfFiles = Get-ChildItem -Path "$SourceFolder" -Include '*.inf' -Recurse

# Format Source folder for regexp
$SourceRegExp = $SourceFolder -replace ('\\', '\\')

# Create destination folder if it doesn't exist
if (!(Test-Path -Path $DestFolder -ErrorAction SilentlyContinue))
{
    New-Item -Path $DestFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

# Copy only matching files and increment file size
$DestSize = 0
foreach ($file in $InfFiles)
{
    Write-Host "INF File: $($file.FullName)"
    # Get dependencies from INF
    $InfContents = Get-Content -Path $file.FullName
    $DriverClass = (($InfContents | Select-String 'Class=') -split('='))[1]

    # Copy SourceDisksFiles
    for ($i = 0; $i -lt $InfContents.Count; $i++)
    {
        if ($InfContents[$i] -eq '[SourceDisksFiles]')
        {
            $SDF = $i
        }

        if ($InfContents[$i] -eq '[SourceDisksFiles.amd64]')
        {
            $SDF64 = $i
        }

        if ($SDF -and $SDF64)
        {
            break
        }
    }

    if ($SDF)
    {
        CopyFiles -StartLine $SDF -InfSource $InfContents -Source $file.Directory -Dest $DestFolder -Class $DriverClass
    }

    if ($SDF64)
    {
        CopyFiles -StartLine $SDF64 -InfSource $InfContents -Source $file.Directory -Dest $DestFolder -Class $DriverClass
    }
    Copy-Item -Path "$($file.FullName)" -Destination "$DestFolder\$DriverClass" -Force

    Clear-Variable -Name SDF, SDF64
}

# Display total size of copies files
#Write-Host "New folder size: $($DestSize / 1mb)"