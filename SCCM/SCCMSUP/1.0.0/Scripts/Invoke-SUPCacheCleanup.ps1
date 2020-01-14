function Invoke-SUPCacheCleanup
{
    <#
    .SYNOPSIS
    Clean up SUP cache on remote computers.

    .DESCRIPTION
    Clear out SCCM cache and/or reset the windows update database on remote computers. This can aid in troubleshooting software download and installation issues.

    .PARAMETER ComputerName
    The name of the remote computer.

    .PARAMETER Action
    Which actions to perform.

    .EXAMPLE
    Invoke-SUPCacheCleanup -ComputerName pc001.test.local -Action Both

    .EXAMPLE
    Invoke-SUPCacheCleanup -ComputerName pc001.test.local -Action CMCache

    .NOTES
        FileName: Invoke-SUPCacheCleanup.ps1
        Original Author: Andrew Ogden
        Original Contact: andrew.ogden@dxpe.com
        Created: 2020-01-14

        ChangeLog:
        
    #>
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('CMCache','WUCache','Both')]
        [string]$Action
    )

    begin
    {
        try
        {
            $CacheSession = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        }
        catch
        {
            Write-Error "$(Get-Date -UFormat "%m/%d/%y - %H:%M:%S") > ERROR: Failed to create session for $ComputerName)"
            throw -ForegroundColor Yellow -Object $($error[0].Exception.Message)
        }
    }

    process
    {
        # Cleanup CMCache
        if (($Action -eq 'CMCache') -or ($Action -eq'Both'))
        {
            # How big is the CM Cache?
            # We'll access the remote session a first time here to set up the COM object
            # and gather some preliminary data. We're also saving the cache size into a
            # local variable here for some reporting
            $CMCacheInit = Invoke-Command -Session $CacheSession -ScriptBlock {
                # Create CM object and gather cache info
                $cm = New-Object -ComObject UIResource.UIResourceMgr
                $cmcache = $cm.GetCacheInfo()
                $CacheElements = $cmcache.GetCacheElements()

                # Create custom object to report back interesting data
                $localCache = New-Object -TypeName psobject
                $localCache | Add-Member -MemberType NoteProperty -Name TotalSize -Value $($cmcache.TotalSize)
                $localCache | Add-Member -MemberType NoteProperty -Name UsedSpace -Value $(($cmcache.TotalSize - $cmcache.FreeSize))
                $localCache | Add-Member -MemberType NoteProperty -Name ItemCount -Value $($CacheElements.Count)

                # Return the object to the local session
                $localCache
             }

            # Clear the CM cache
            # Now we're accessing the session a second time to clear the cache (assuming it's not  already empty)
            $CMCacheRes = Invoke-Command -Session $CacheSession -ScriptBlock {
                if ($CacheElements.Count -gt 0)
                {
                    # Remove each object
                    foreach ($CacheObj in $CacheElements)
                    {
                        # Delete content object
                        $eid = $CacheObj.CacheElementId
                        $cmcache.DeleteCacheElement($eid)
                    }
                }

                # Update with new cache info
                $cm = New-Object -ComObject UIResource.UIResourceMgr
                $cmcache = $cm.GetCacheInfo()
                $CacheElements = $cmcache.GetCacheElements()

                $localCache = New-Object -TypeName psobject
                $localCache | Add-Member -MemberType NoteProperty -Name TotalSize -Value $($cmcache.TotalSize)
                $localCache | Add-Member -MemberType NoteProperty -Name UsedSpace -Value $(($cmcache.TotalSize - $cmcache.FreeSize))
                $localCache | Add-Member -MemberType NoteProperty -Name ItemCount -Value $($CacheElements.Count)

                # Return the object to the local session
                $localCache
            }
        }

        # Reset WU DB
        if (($Action -eq 'WUCache') -or ($Action -eq'Both'))
        {
            # This time we're going to access the remote session to count the size of the 
            # WU cache and add that to the existing variable
            $WUCacheInit = Invoke-Command -Session $CacheSession -ScriptBlock {
                $SizeCount = 0
                foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
                {
                    $SizeCount += $f.Length
                }

                # Report size in mb
                $("{0:N2}" -f $($SizeCount / 1mb))
            }

            # Now we hop back into the remote session again to finish clearing
            # out the WU cache
            Invoke-Command -Session $CacheSession -ScriptBlock {
                Set-Service -Name wuauserv -StartupType Disabled
                Stop-Service wuauserv -Force -WarningAction SilentlyContinue
                Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Force -Recurse

                # Restart WU and wait a few seconds for it to create a new cache folder
                Set-Service -Name wuauserv -StartupType Automatic
                Start-Service wuauserv -WarningAction SilentlyContinue
                Start-Sleep -Seconds 10

                # Verify that a new cache folder was created and throw an error if not
                if (!(Get-Item -Path "$env:SystemRoot\SoftwareDistribution"))
                {
                    Write-Error -Object "Failed to recreate SoftwareDistribution folder!" -ForegroundColor Red
                }
            }

            # We're accessing the session again a final time to determine the new size of the
            # WU cache to subtract from our saved space
            $WUCacheRes = Invoke-Command -Session $CacheSession -ScriptBlock {
                $SizeCount = 0
                foreach ($f in (Get-childItem -Path "$env:SystemRoot\SoftwareDistribution" -Recurse))
                {
                    $SizeCount += $f.Length
                }

                # Report size in mb
                $("{0:N2}" -f $($SizeCount / 1mb))
            }
        }
    }

    end
    {
        # Clean up the session when done
        try
        {
            Remove-PSSession -Session $CacheSession -ErrorAction Stop
        }
        catch
        {
            Write-Error "ERROR: Failed to clean up session for $($ComputerName)"
            Write-Error -ForegroundColor Yellow -Object $($error[0].Exception.Message)
        }

        # Create an object to hold data about the operations
        $resultObj = New-Object -TypeName psobject
        $resultObj | Add-Member -MemberType NoteProperty -Name WUCacheInitSize -Value $WUCacheInit
        $resultObj | Add-Member -MemberType NoteProperty -Name WUCacheResSize -Value $WUCacheRes
        $resultObj | Add-Member -MemberType NoteProperty -Name CMCacheInitSize -Value $CMCacheInit.UsedSpace
        $resultObj | Add-Member -MemberType NoteProperty -Name CMCacheInitCount -Value $CMCacheInit.ItemCount
        $resultObj | Add-Member -MemberType NoteProperty -Name CMCacheResSize -Value $CMCacheRes.UsedSpace
        $resultObj | Add-Member -MemberType NoteProperty -Name CMCacheResCount -Value $CMCacheRes.ItemCount
        $resultObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName

        # Return the result object
        return $resultObj
    }
}