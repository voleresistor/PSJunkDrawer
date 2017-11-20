param(
    [string]$HomeDirPath = "\\dxpe.com\homedir",
    [string]$Url,
    [string]$Name,
    [switch]$Test
)

Clear-Host
Write-Host "=============== " -NoNewLine
Write-Host "New-IEFavorite" -NoNewline -ForegroundColor Cyan
Write-Host " ==============="

$homedirRoots = Get-ChildItem -Path $HomeDirPath -Attributes Directory

foreach ($root in $homedirRoots){
    $homedirs = Get-ChildItem -Path $($root.FullName) -Attributes Directory

    foreach ($h in $homedirs){
        $ShortCutPath = "$($h.FullName)\Favorites\$Name.url"
    
        Write-Host "`r`nCreating shortcut " -NoNewline
        Write-Host "$ShortCutPath" -NoNewline -ForegroundColor Yellow
        Write-Host "..." -NoNewline
    
        if (!$Test){
            $Shell = New-Object -ComObject WScript.Shell
            $ShortCut = $Shell.CreateShortCut($ShortCutPath)
            $ShortCut.TargetPath = $Url
            $ShortCut.Save()
        }
    
        if ($Test){
            Write-Host " Test" -ForegroundColor Green
        } elseif (Test-Path -Path $ShortCutPath){
            Write-Host " Done" -ForegroundColor Green
        } else {
            Write-Host " Failed" -ForegroundColor Red
        }
    }
}