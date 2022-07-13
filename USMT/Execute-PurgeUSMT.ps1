$StorePath = 'D:\config\MICROSOFT\USMT_Supergrate\STORE'
$ageDays = 6
$todayDate = Get-Date -UFormat "%m-%d-%y"
$logPath = "c:\scripts\logs"
$logName = "PurgeUSMT_$todayDate.log"
$logFull = "$logPath\$logName"

# Set up log
if (!(Test-Path -Path $logPath)) {
    New-Item -Path $logPath -Force -ItemType Directory
}

# Verify store folder is where we expect
If (!(Test-Path -Path $StorePath)) {
    Add-Content -Value "ERROR: Can't find $StorePath" -Path $logFull
    exit 42069
} else {
    Add-Content -Value "Found $StorePath" -Path $logFull
}

# Where are we?
Add-Content -Value "Current path: $((Get-Location).Path)" -Path $logFull

#$oldContent = Get-ChildItem -Path $StorePath | Where-Object {$_.LastWriteTime -lt ((Get-Date).AddDays(-$ageDays))}
foreach ($u in (Get-ChildItem -Path $StorePath)) {
    if ($u.LastWriteTime -lt ((Get-Date).AddDays(-$ageDays))) {
        Add-Content -Value "Removing $($u.Name) created on $($u.CreationTime)" -Path $logFull
        Remove-Item -Path $u.FullName -Recurse
    } else {
        Add-Content -Value "Keeping $($u.Name) created on $($u.CreationTime)" -Path $logFull
    }
}
