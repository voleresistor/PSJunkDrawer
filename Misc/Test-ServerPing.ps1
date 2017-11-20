# Test-ServerPing.ps1
#
# Andrew Ogden
# aogden@dxpe.com
# 05/06/2015
#
# Last Update
# 05/08/2015
#
# Test server status via ping or SMB. Useful for troubleshooting intermittent failures by allowing
# the user to rapidly identify when the server becomes unavailable.
#
# TODO:
#      Add math in marker to allow custom ping and marker intervals to be accurate - DONE
#      Check that DNS names resolve before attempting to ping - DONE
#      Add reset for fail counter to limit to a certain numbr of failures per attempts - DONE necessitated consecutivity for failures
#      Add option to test SMB connection - DONE
#

param (
    [string]$ComputerName, # Computername to ping
    [string]$TestPath, # Path to test for SMB connectivity
    [single]$MarkerMinutes = 30, # Number of minutes between time markers
    [single]$MaxFailures = 3, # Maximum failures allowed within a certain time
    [single]$PingInterval = 60, # Number of seconds to sleep between pings
    [switch]$Test, # Print extra diagnostic messages while running
    [string]$AutoRestart, # Name of the server to reboot
    [string]$LogPath # Path to folder where logs should be written
    # Using these defaults, the script will ping every 60 seconds, mark every 30 minutes and exit
    # if the server is unresponsive for 3 minutes
)

function check-input(){
    if ($TestPath -and !$ComputerName){
        $type = "SMB"
    } elseif ($ComputerName -and !$TestPath){
        $type = "ping"
    } else {
        Write-Host "ERROR: -ComputerName and -TestPath are mutually exclusive options"
    }

    return $type
}

# Return 1 if ping failed or return 0 if ping succeeded
function perform-test (
    [string]$name,
    [string]$path,
    [string]$log
){
    if ($name -and !$path){
        if ((Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -eq $false){
            Write-Host "Ping to $name ($($ipaddress.IPAddress)) failed at $(Get-Date)." -ForegroundColor Red
            if ($log){
                Add-Content -Value "Ping to $name ($($ipaddress.IPAddress)) failed at $(Get-Date)." -Path $log
            }
            Return 1
        } else {
            Write-Host "Ping to $name ($($ipaddress.IPAddress)) successful." -ForegroundColor Green
            if ($log){
                Add-Content -Value "Ping to $name ($($ipaddress.IPAddress)) successful." -Path $log
            }
            Return 0
        }
    } elseif ($path -and !$name){
        if ((Test-Path -Path $path -ErrorAction SilentlyContinue) -eq $false){
            Write-Host "Path $path not accessible at $(Get-Date)." -ForegroundColor Red
            if ($log){
                Add-Content -Value "Path $path not accessible at $(Get-Date)." -Path $log
            }
            Return 1
        } else {
            Write-Host "Path $path is available." -ForegroundColor Green
            if ($log){
                Add-Content -Value "Path $path is available." -Path $log
            }
            Return 0
        }
    }
}

# Return time in minutes for mark if mark reached or return 0 if not
# Convert mark time to hours if at least 60 minutes
function check-marker(
    [single]$count, # Number of pings since last mark
    [single]$limit, # Number of ping between marks
    [single]$interval, # Number of minutes between marks
    [single]$cycles # Number of marks
){
    if ($count -eq $limit){
        [single]$return = ($interval * $cycles)
        Return $return
    } else {
        Return 0
    }
}

function restart-server($log){
    Get-Process | Sort HandleCount -Descending > C:\temp\process_dump-$(get-date -Format MMddyy).txt
    netstat > C:\temp\net_dump-$(get-date -format MMddyy).txt
    Restart-Computer -ComputerName $AutoRestart -Force

    Write-Host "Sleeping while server reboots..."
    if ($log){
        Add-Content -Value "Sleeping while server reboots..." -Path $log
    }
    
    while ((Test-Path -Path $TestPath) -ne $true){
        Start-Sleep -Seconds 10
    }
}

function main (){
    [bool]$firstRun = $true # One time use. Skips Start-Sleep on first run
    [bool]$EXIT = $false # Loop while this remains $false
    [bool]$hours = $false # Mark in minutes while false
    [string]$markUnit = "minutes"
    [single]$markerCount = 1 # Number of pings since last mark
    [single]$failCount = 1 # Number of failures in last failure period
    [single]$intervalInMinutes = ($pingInterval / 60) # User defined ping interval converted from seconds to minutes
    [single]$pingsBetweenMark = ($MarkerMinutes / $intervalInMinutes) # Number of pings between each mark
    [single]$cycles = 1 # Number of mark cycles since start
    [int]$testResult = 0 # Integer for recieving results from tests
    [string]$checkType = (check-input)

    if ($LogPath){
        $logFile = $LogPath + "\goldendfs01_" + (Get-Date -Format MMdd-hh) + ".log"
    }

    if ($checkType -eq "ping"){
        $ipaddress = (Resolve-DnsName -Name $ComputerName -ErrorAction SilentlyContinue)
        if (!$ipaddress){
            Write-Host "Computername can not be resolved." -ForegroundColor Red
            exit 1
        }
    }

    while ($EXIT -eq $false){
        
        if ($firstRun -ne $true){
            Start-Sleep -Seconds $pingInterval
        } else {
            $firstRun = $false
        }

        switch ($checkType){
            "SMB" {
                $testResult = (perform-test -path $TestPath -log $logFile)
            }

            "ping" {
                $testResult = (perform-test -name $ComputerName -log $logFile)
            }
        }

        if ($testResult -eq 1){
            $failCount++
        } elseif ($failCount -ge 1) {
            $failCount = 0
        }

        $mark = check-marker -count $markerCount -limit $pingsBetweenMark -interval $MarkerMinutes -cycles $cycles
        if ($mark -ge 60){
            $markUnit = "hours"
            $mark = ($mark /60)
        }
        if ($mark -ne 0){
            Write-Host "========== $mark $markUnit $(Get-Date) =========="
            if ($LogPath){
                Add-Content -Value "========== $mark $markUnit $(Get-Date) ==========" -Path $logFile
            }
            $markerCount = 0
            $cycles++
        }

        if ($failCount -eq $MaxFailures){
            Write-Host "Server $ComputerName or path $TestPath is offline." -ForegroundColor Cyan
            if ($logFile){
                Add-Content -Value "Server $ComputerName or path $TestPath is offline." -Path $logFile
            }

            if ($AutoRestart){
                Restart-Server
            } else {
                $EXIT = $true
            }
        }

        $markerCount++
    }
}

main