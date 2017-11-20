param(
    [switch]$Dept,
    [switch]$Projects,
    [switch]$Public,
    [switch]$Temp,
    [switch]$Citrix,
    [switch]$EDI,
    [switch]$HelpDesk,
    [switch]$HomeDir,
    [switch]$Profiles,
    [switch]$Programs,
    [switch]$Repo,
    [switch]$UPM,
    [switch]$Data,
    [switch]$all
)

# Remove files greater than four weeks old to keep the folder from
# getting filled with old reports
$oldFiles = (Get-ChildItem -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure" -Attributes !D+!H+!S)
foreach ($oldfile in $oldfiles){
    if ((New-TimeSpan -Start $($oldfile.CreationTime) -End (Get-Date)).Days -ge 28){
        Remove-Item -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\$($oldFile.Name)" -Force
    }
}

# Create a suffix for files in the format dd-mm-yy
$dateSuf = (Get-Date -UFormat %d-%m-%y)

# Gather folder target information for each root (and the four folders in Data) and write the interesting properties to a CSV file
if ($Dept){
    $Departments = (Get-DFSNFolder -Path "\\dxpe.com\data\departments\*" | Select-Object -Property Path)
    foreach ($folder in $Departments){
        Get-DFSNFolderTarget -Path $($folder.Path) | Select-Object -Property NamespacePath,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Data_Departments_$dateSuf.csv" -Append
    }
}

# Some folders or roots have no structure below them and do not need the loop.
# Loop commented out, but left intact for future expansion if folder is changed
if ($Projects){
    #$Projects = (Get-DFSNFolder -Path "\\dxpe.com\data\Projects\*" | Select-Object -Property Path)
    #foreach ($folder in $Projects){
        Get-DFSNFolderTarget -Path "\\dxpe.com\data\Projects" | Select-Object -Property NamespacePath,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Data_Projects_$dateSuf.csv" -Append
    #}
}
if ($Public){
    $PublicFolders = (Get-DFSNFolder -Path "\\dxpe.com\data\Public\*" | Select-Object -Property Path)
    foreach ($folder in $PublicFolders){
        Get-DFSNFolderTarget -Path $($folder.Path) | Select-Object -Property NamespacePath,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Data_Public_$dateSuf.csv" -Append
    }
}
if ($Temp){
    #$TempFolders = (Get-DFSNFolder -Path "\\dxpe.com\data\Temp\*" | Select-Object -Property Path)
    #foreach ($folder in $TempFolders){
        Get-DFSNFolderTarget -Path "\\dxpe.com\data\Temp" | Select-Object -Property NamespacePath,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Data_Temp_$dateSuf.csv" -Append
    #}
}
if ($Data -or $all){
    $DataFolders = (Get-DFSNFolder -Path "\\dxpe.com\data\*" | Select-Object -Property Path)
    foreach ($folder in $DataFolders){
        Get-DFSNFolderTarget -Path $($folder.Path) | Select-Object -Property NamespacePath,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Data_$dateSuf.csv" -Append
    }
}
if ($Citrix -or $all){
    #$TempFolders = (Get-DFSNFolder -Path "\\dxpe.com\data\Temp\*" | Select-Object -Property Path)
    #foreach ($folder in $TempFolders){
        Get-DFSNRootTarget -Path "\\dxpe.com\Citrix" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Citrix_$dateSuf.csv" -Append
    #}
}
if ($EDI -or $all){
    $EDIFolders = (Get-DFSNFolder -Path "\\dxpe.com\EDI\*" | Select-Object -Property Path)
    foreach ($folder in $EDIFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\EDI_$dateSuf.csv" -Append
    }
}
if ($HelpDesk -or $all){
    $HelpDeskFolders = (Get-DFSNFolder -Path "\\dxpe.com\HelpDesk\*" | Select-Object -Property Path)
    foreach ($folder in $HelpDeskFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\HelpDesk_$dateSuf.csv" -Append
    }
}
if ($HomeDir -or $all){
    $HomeDirFolders = (Get-DFSNFolder -Path "\\dxpe.com\HomeDir\*" | Select-Object -Property Path)
    foreach ($folder in $HomeDirFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\HomeDir_$dateSuf.csv" -Append
    }
}
if ($Profiles -or $all){
    $ProfileFolders = (Get-DFSNFolder -Path "\\dxpe.com\Profiles\*" | Select-Object -Property Path)
    foreach ($folder in $ProfileFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Profiles_$dateSuf.csv" -Append
    }
}
if ($Programs -or $all){
    $ProgramFolders = (Get-DFSNFolder -Path "\\dxpe.com\Programs\*" | Select-Object -Property Path)
    foreach ($folder in $ProgramFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\Programs_$dateSuf.csv" -Append
    }
}
if ($UPM -or $all){
    $UPMFolders = (Get-DFSNFolder -Path "\\dxpe.com\UPM\*" | Select-Object -Property Path)
    foreach ($folder in $UPMFolders){
        Get-DFSNFolderTarget -Path "$($folder.Path)" | Select-Object -Property Path,TargetPath,State | Export-CSV -Path "\\dxpe.com\Data\Departments\IT\Sysops\DFS\Structure\UPM_$dateSuf.csv" -Append
    }
}