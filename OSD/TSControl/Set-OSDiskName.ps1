param
(
    [string]$OSDiskLetter = 'C',
    [string]$NewOSDiskName = 'OSDisk'
)

if (!(Get-Volume -FileSystemLabel $NewOSDiskName -ErrorAction SilentlyContinue))
{
    Write-Host "System disk labeled $NewOSDiskName not found!" -ForegroundColor Yellow
    
    $OSDisk = Get-Volume -DriveLetter $OSDiskLetter
    Write-host "Found Drive C: labeled $($OSDisk.FileSystemLabel)"
    
    Write-Host "Renaming $($OSDisk.FileSystemLabel) to $NewOSDiskName"
    Set-Volume -FileSystemLabel $($OSDisk.FileSystemLabel) -NewFileSystemLabel $NewOSDiskName -ErrorAction SilentlyContinue
    
    if (!(Get-Volume -FileSystemLabel $NewOSDiskName -ErrorAction SilentlyContinue))
    {
        Write-Host "Failed to relabel system disk!" -ForegroundColor Red
        exit 07
    }
    else
    {
        Write-Host "Disk label updated!" -ForegroundColor Green
        exit 0
    }
}
else
{
    Write-Host "System disk already labeled $NewOSDiskName!" -ForegroundColor Green
    exit 0
}