<#
******************************************
Name: Clear-CMCache
Purpose: Remotely clear c:\windows\ccmcache on target computers
Author: Andrew Ogden
Email: andrew.ogden@dxpe.com

Scriptblock function borrowed from user 0byt3 in this Reddit thread: https://www.reddit.com/r/SCCM/comments/3m8uh9/script_sms_client_to_clear_cache_then_install/
#>
param
(
    [array]$ComputerName,
    [switch]$ResetWUCache
)

For ($i = 0; $i -lt $($ComputerName.Count); $i++)
{
    # Create a session object for easy cleanup so we aren't leaving half-open
    # remote sessions everywhere
    try
    {
        Write-Progress -Activity "Clearing remote caches..." -Status "$($ComputerName[$i]) ($i/$($ComputerName.Count))" -PercentComplete ($($i/$($ComputerName.Count))*100)
        $CacheSession = New-PSSession -ComputerName $ComputerName[$i] -ErrorAction Stop
    }
    catch
    {
        Write-Host "$(Get-Date -UFormat "%m/%d/%y - %H:%M:%S") > ERROR: Failed to create session for $($ComputerName[$i])"
        Write-Host -ForegroundColor Yellow -Object $($error[0].Exception.Message)
        continue
    }

    # How big is the CM Cache?
    # We'll access the remote session a first time here to set up the COM object
    # and gather some preliminay data. We're also saving the cache size into a
    # local variable here for some reporting
    $SpaceSaved = Invoke-Command -Session $CacheSession -ScriptBlock {
        # Create CM object and gather cache info
        $cm = New-Object -ComObject UIResource.UIResourceMgr
        $cmcache = $cm.GetCacheInfo()
        $CacheElements = $cmcache.GetCacheElements()

        # Report space in use back to the local variable in MB
        $(($cmcache.TotalSize - $cmcache.FreeSize))
     }

    # Clear the CM cache
    # Now we're accessing the session a second time to clear the cache (assuming it's not  already empty)
    Invoke-Command -Session $CacheSession -ScriptBlock {
        if ($CacheElements.Count -gt 0)
        {
            # Echo total cache size
            Write-Host "$(($cmcache.TotalSize - $cmcache.FreeSize))" -NoNewline -ForegroundColor Yellow
            Write-Host " MB used by $(($cmcache.GetCacheElements()).Count) cache items on $env:computername"

            # Remove each object
            foreach ($CacheObj in $CacheElements)
            {
                # Log individual elements
                $eid = $CacheObj.CacheElementId
                #Write-Host "Removing content ID $eid with size $(($CacheObj.ContentSize) / 1000)MB from $env:ComputerName"

                # Delete content object
                $cmcache.DeleteCacheElement($eid)
            }
        }
        else
        {
            Write-Host "Cache already empty on $env:ComputerName!"
        }
    }

    # Clean the WU cache (if requested)
    if ($ResetWUCache)
    {
        # This time we're going to access the remote session to count the size of the 
        # WU cache and add that to the existing variable
        $SpaceSaved += Invoke-Command -Session $CacheSession -ScriptBlock {
            $SizeCount = 0
            foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
            {
                $SizeCount += $f.Length
            }

            # Report size in mb
            $SizeCount / 1mb
        }

        # Now we hop back into the remote session again to finish clearing
        # out the WU cache
        Invoke-Command -Session $CacheSession -ScriptBlock {
            Stop-Service wuauserv -Force -WarningAction SilentlyContinue

            Write-Host "Resetting WU Cache on $env:ComputerName..."
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Force -Recurse

            # Restart WU and wait a few seconds for it to create a new cache folder
            Start-Service wuauserv -WarningAction SilentlyContinue
            Start-Sleep -Seconds 10

            # Verify that a new cache folder was created and throw an error if not
            if (!(Get-Item -Path "$env:SystemRoot\SoftwareDistribution"))
            {
                Write-Host -Object "Failed to recreate SoftwareDistribution folder!" -ForegroundColor Red
            }
        }

        # We're accessing the session again a final time to determine the new size of the
        # WU cache to subtract from our saved space
        $SpaceSaved -= Invoke-Command -Session $CacheSession -ScriptBlock {
            $SizeCount = 0
            foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
            {
                $SizeCount += $f.Length
            }

            # Report size in mb
            $SizeCount / 1mb
        }
    }

    # Report the space saved
    Write-Host -Object "Space saved on $($ComputerName[$i]): " -NoNewline
    Write-Host -Object $("{0:N2}" -f $SpaceSaved) -ForegroundColor Green -NoNewline
    Write-Host -Object " MB"

    # Clean up the session when done
    try
    {
        Remove-PSSession -Session $CacheSession -ErrorAction Stop
    }
    catch
    {
        Write-Host "ERROR: Failed to clean up session for $($ComputerName[$i])"
        Write-Host -ForegroundColor Yellow -Object $($error[0].Exception.Message)
        continue
    }

    # Clean up this variable to ensure that it doesn't bleed into subsequent iterations
    Clear-Variable -Name SpaceSaved
}

<#
$cm = New-Object -ComObject UIResource.UIResourceMgr
$cmcache = $cm.GetCacheInfo()
$CacheElements = $cmcache.GetCacheElements()
$cmcache

$CacheElements | foreach-object { $eid = $_.cacheelementid; $cmcache.deletecacheelement($eid) }
#>