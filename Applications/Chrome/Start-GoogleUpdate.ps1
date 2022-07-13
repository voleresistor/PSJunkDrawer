function Start-GoogleUpdate {
    param(
        [switch]$Silent
    )

    # Chrome updater paths
    $x86Updater = 'C:\Program Files (x86)\Google\Update'
    $x64Updater = 'C:\Program Files\Google\Update'

    # Do one or both of these exist?
    # 0 - Neither
    # 1 - x86
    # 2 - x64
    # 3 - Both
    $updaterPresence = 0
    if (Test-Path -Path $x86Updater -ErrorAction SilentlyContinue) {
        $updaterPresence += 1
    }
    if (Test-Path -Path $x64Updater -ErrorAction SilentlyContinue) {
        $updaterPresence += 2
    }

    # Perform updates
    if ($updaterPresence -eq 1 -or $updaterPresence -eq 3) {
        # x86 update
        Start-Process -FilePath "$x86Updater\GoogleUpdate.exe" -ArgumentList '' -NoNewWindow -Wait
    }

    if ($updaterPresence -eq 2 -or $updaterPresence -eq 3) {
        # x64 update
        Start-Process -FilePath "$x64Updater\GoogleUpdate.exe" -ArgumentList '' -NoNewWindow -Wait
    }

    if ($updaterPresence -eq 0) {
        Write-Warning "No updater found. Is Chrome installed correctly?"
    }
}