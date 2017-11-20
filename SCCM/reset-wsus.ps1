function Reset-Wsus
{
    param
    (
        [string]$ComputerName = $env.LocalHost,
        [string]$WsusFolder = "$env:SystemRoot\SoftwareDistribution"
    )
    try
    {
        # Service holds files open in cache. Must be stopped to continue
        Write-Host "Stopping Windows Update service... " -NoNewline
        Stop-Service -Name wuauserv -Force
    }
    catch
    {
        return '[reset-wsus.ps1] ERROR: Failed to stop Windows Update service'
    }

    # Double check that service is stopped to prevent files from being held open
    if ((Get-Service -Name wuauserv).Status -ne 'Stopped')
    {
        Write-Host "FAILED" -ForegroundColor Red
        return '[reset-wsus.ps1] ERROR: Windows Update Service still running'
    }
    else
    {
        try
        {
            # Deleting this will cause WUAU to build a fresh one
            Write-Host "DONE" -ForegroundColor Green
            Write-Host "Deleting old Windows Update cache... " -NoNewline
            Remove-Item -Path $WsusFolder -Recurse -Force
        }
        catch
        {
            Write-Host "FAILED" -ForegroundColor Red
            return '[reset-wsus.ps1] ERROR: Failed to remove Windows Update cache folder'
        }
    }

    if (!(Test-Path -Path $WsusFolder))
    {
        Write-Host "DONE" -ForegroundColor Green
    }

    try
    {
        Write-Host "Restarting Windows Update service... " -NoNewline
        Start-Service -Name wuauserv
    }
    catch
    {
        Write-Host "FAILED" -ForegroundColor Red
        return '[reset-wsus.ps1] ERROR: Failed to restart Windows Update service'
    }

    Write-Host "DONE" -ForegroundColor Green
}