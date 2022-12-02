# Services that should be stopped and restarted
$Services = @(
    'bits',
    'wuauserv',
    'appidsvc',
    'cryptsvc'
)

# Files and folders to delete
$Files = @(
    "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\*.*",
    "$env:systemroot\SoftwareDistribution",
    "$env:systemroot\system32\catroot2",
    "$env:systemroot\System32\GroupPolicy\Machine\Registry.pol",
    "$env:systemroot\System32\GroupPolicy\Machine\comment.cmtx"
)

# Command strings for sc.exe to reset Windows Update
$ScStrings = @(
    'sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)',
    'sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'
)

# DLLs to re-register
$RegDlls = @(
    'atl.dll',
    'urlmon.dll',
    'mshtml.dll',
    'shdocvw.dll',
    'browseui.dll',
    'jscript.dll',
    'vbscript.dll',
    'scrrun.dll',
    'msxml.dll',
    'msxml3.dll',
    'msxml6.dll',
    'actxprxy.dll',
    'softpub.dll',
    'wintrust.dll',
    'dssenh.dll',
    'rsaenh.dll',
    'gpkcsp.dll',
    'sccbase.dll',
    'slbcsp.dll',
    'cryptdlg.dll',
    'oleaut32.dll',
    'ole32.dll',
    'shell32.dll',
    'initpki.dll',
    'wuapi.dll',
    'wuaueng.dll',
    'wuaueng1.dll',
    'wucltui.dll',
    'wups.dll',
    'wups2.dll',
    'wuweb.dll',
    'qmgr.dll',
    'qmgrprxy.dll',
    'wucltux.dll',
    'muweb.dll',
    'wuwebv.dll'
)

# Reset sockets
$Sockets = @(
    'winsock reset',
    'winsock reset proxy'
)

# Get current size of the folder
$currentSize = [Math]::Round((Get-ChildItem -Recurse -File -Path C:\Windows\SoftwareDistribution\ | Measure-Object -Sum -Property Length).Sum / 1gb, 2)

# Track errors
$status = $null
$progress = @{
    'InitialSize' = $currentSize
}
$success = $true

# Stop services
$Services | %{
    try {
        Write-Progress -Activity "Stopping services..." -Status "$_ ($($Services.IndexOf($_) + 1)/$($Services.Count))" -PercentComplete $($($Services.IndexOf($_)) / $($Services.Count) * 100)
        Stop-Service -Name $_ -Force -ErrorAction Stop
        $status = 'Stopped'
    }
    catch {
        Write-Output "Error: $($_.Exception.Message)"
        $status = 'StopFail'
        $success = $false

        # Update progress hashtable
        if ($progress.Keys -contains $_) {
            $progress[$_] = $status
        }
        else {
            $progress.Add($_, $status)
        }
    }
}

# Remove files
if ($success) {
    $Files | %{
        try {
            Write-Progress -Activity "Removing files and folders..." -Status "$_ ($($Files.IndexOf($_) + 1)/$($Files.Count))" -PercentComplete $($($Files.IndexOf($_)) / $($Files.Count) * 100)
            if (Test-Path -Path $_ -ErrorAction SilentlyContinue) {
                Remove-Item -Path $_ -Force -Recurse -ErrorAction Stop
                $status = 'Deleted'
            }
            else {
                $status = 'NotPresent'
            }
        }
        catch {
            Write-Output "Error: $($_.Exception.Message)"
            $status = 'DelFail'
            $success = $false

            # Update progress hashtable
            if ($progress.Keys -contains $_) {
                $progress[$_] = $status
            }
            else {
                $progress.Add($_, $status)
            }
        }
    }
}

# Reset services
if ($success) {
    $ScStrings | %{
        try {
            Write-Progress -Activity "Resetting services..." -PercentComplete $($($ScStrings.IndexOf($_)) / $($ScStrings.Count) * 100)
            Start-Process -FilePath "$env:windir\system32\sc.exe" -ArgumentList $_ -Wait -NoNewWindow -ErrorAction Stop
            $status = 'Success'
        }
        catch {
            Write-Output "Error: $($_.Exception.Message)"
            $status = 'Fail'
            $success = $false

            # Update progress hashtable
            if ($progress.Keys -contains $_) {
                $progress[$_] = $status
            }
            else {
                $progress.Add($_, $status)
            }
        }
    }
}

# Re-register DLLs
if ($success) {
    $RegDlls | %{
        try {
            Write-Progress -Activity "Registering DLLs..." -Status "$_ ($($RegDlls.IndexOf($_) + 1)/$($RegDlls.Count))" -PercentComplete $($($RegDlls.IndexOf($_)) / $($RegDlls.Count) * 100)
            Start-Process -FilePath "$env:windir\system32\regsvr32.exe" -ArgumentList "/s $_" -Wait -NoNewWindow -ErrorAction Stop
            $status = 'Registered'
        }
        catch {
            Write-Output "Error: $($_.Exception.Message)"
            $status = 'RegFail'
            $success = $false

            # Update progress hashtable
            if ($progress.Keys -contains $_) {
                $progress[$_] = $status
            }
            else {
                $progress.Add($_, $status)
            }
        }
    }
}

# Reset sockets
if ($success) {
    $Sockets | %{
        try {
            Write-Progress -Activity "Resetting sockets..." -Status "$_ ($($Sockets.IndexOf($_) + 1)/$($Sockets.Count))" -PercentComplete $($($Sockets.IndexOf($_)) / $($Sockets.Count) * 100)
            Start-Process -FilePath "$env:windir\system32\netsh.exe" -ArgumentList $_ -Wait -NoNewWindow -ErrorAction Stop
            $status = 'Reset'
        }
        catch {
            Write-Output "Error: $($_.Exception.Message)"
            $status = 'ResetFail'
            $success = $false

            # Update progress hashtable
            if ($progress.Keys -contains $_) {
                $progress[$_] = $status
            }
            else {
                $progress.Add($_, $status)
            }
        }
    }
}

# Restart services
$Services | %{
    try {
        Write-Progress -Activity "Starting services..." -Status "$_ ($($Services.IndexOf($_) + 1)/$($Services.Count))" -PercentComplete $($($Services.IndexOf($_)) / $($Services.Count) * 100)
        Set-Service -Name $_ -StartupType Automatic
        Start-Service -Name $_ -ErrorAction Stop
        $status = 'Restarted'
    }
    catch {
        Write-Output "Error: $($_.Exception.Message)"
        $status = 'StartFail'

        # Update progress hashtable
        if ($progress.Keys -contains $_) {
            $progress[$_] = $status
        }
        else {
            $progress.Add($_, $status)
        }
    }
}

Write-Output $success
Write-Output $progress