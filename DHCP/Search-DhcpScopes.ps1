<# 
Name: Seach-DhcpScopes.ps1

Created by: Andrew Ogden
            aogden@dxpe.com
            03/02/2015

Description: Quickly get info about unknown subnets by automatically querying
                a list of active DHCP servers.

Changes:
        
#>

param (
    [string]$ScopeID,
    [array]$DhcpServers = @("hou-dc-03.dxpe.corp", "hou-dc-04.dxpe.corp", "omwdhcp02.dxpe.com", "houdhcp02.dxpe.com")
)

# ================================
# Variables
# ================================

$FoundScopes = @()

# ================================
# Main
# ================================

# Make it all pretty with a clear terminal and title
Clear-Host
Write-Host "============ " -NoNewline
Write-Host "Search-DhcpScopes " -ForegroundColor Cyan -NoNewline
Write-Host "============`r`n"

foreach ($s in $DhcpServers){
    Write-Host "Querying $s... " -NoNewline # Keep communicating with the user

    # Make sure this variable is clean before attempting to populate it with scope data
    $ScopeData = $null
    $ScopeData = Get-DhcpServerv4Scope -ComputerName $s -ScopeId $ScopeID -ErrorAction SilentlyContinue 

    if ($ScopeData){ # Test if $ScopeData contains anything
        Write-Host "Found scope data" -ForegroundColor Green # Talk to those users
        $Script:FoundScopes += $ScopeData # Add found data to a hashtable
    }else{
        Write-Host "No scope data found" -ForegroundColor Red # Give em the bad news
    }
}

# Making the user feel good about themselves because a computer is talking to them
Write-Host "`r`nDone searching scopes. Found " -NoNewline
Write-Host "$($FoundScopes.Length) " -ForegroundColor Green -NoNewline
Write-Host "matching scopes:`r`n"

$FoundScopes | Select-Object -Property Name, ScopeID | Format-Table # Finally output some useful data