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