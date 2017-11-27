param(
    [string]$CsvIn,
    [string]$CsvOut,
    [switch]$ComServers,
    [switch]$CorpServers,
    [switch]$PingGateways,
    [switch]$CheckLeases,
    [array]$DhcpServerListCom = @(),
    [array]$DhcpServerListCorp = @()
)

# ************************************************
# Variables
# ************************************************
$CorpCred = $null # Vestigial remnant from a day when I thought I could work both domains. How stupid of me
$ComCred = $null # Vestigial remnant from a day when I thought I could work both domains. How stupid of me
$Results = @{}
$Subnets = Import-Csv -Path $CsvIn

# ************************************************
# Functions
# ************************************************

Function Manage-HashTable{
    param(
        [string]$Subnet,
        [switch]$Yes
    )

    # Identify state of subnet in the hash table
    # Add if it doesn't exist
    # Replace if Yes and it exists as No
    # Do nothing if No and it exists
    if ($Yes){
        if (($Script:Results["$Subnet"]) -and ($Script:Results["$Subnet"] -eq "no")){
            $Script:Results.Remove("$Subnet")
            $Script:Results["$Subnet"] = "yes"
            Return
        }
        
        if (($Script:Results["$Subnet"]) -and ($Script:Results["$Subnet"] -eq "yes")){
            Return
        }

        if (!$Script:Results["$Subnet"]){
            $Script:Results["$Subnet"] = "yes"
            Return
        }
    }else{
        if ($Script:Results["$Subnet"]){
            Return
        }
        
        if (!$Script:Results["$Subnet"]){
            $Script:Results["$Subnet"] = "no"
            Return
        }
    }
}

Function Check-DhcpServers{
    # Run through subnet list and server list to identify which ones are active by the presence of DHCP leases
    foreach ($subnet in $Subnets){
        if ($ComServers){
            foreach ($server in $DhcpServerListCom){
                $ScopeID = $subnet.Boundary -replace "/.*",""
                $ScopeCheck = Get-DhcpServerv4Lease -ComputerName $server -ScopeId $ScopeID -ErrorAction SilentlyContinue
                if ($ScopeCheck){
                    Manage-HashTable -Subnet $ScopeID -Yes
                }

                if (!$ScopeCheck){
                    Manage-HashTable -Subnet $ScopeID
                }
            }
        }

        if ($CorpServers){
            foreach ($server in $DhcpServerListCorp){
                $ScopeID = $subnet.Boundary -replace "/.*",""
                $ScopeCheck = Get-DhcpServerv4Lease -ComputerName $server -ScopeId $ScopeID -ErrorAction SilentlyContinue
                if ($ScopeCheck){
                    Manage-HashTable -Subnet $ScopeID -Yes
                }

                if (!$ScopeCheck){
                    Manage-HashTable -Subnet $ScopeID
                }
            }
        }
    }
}

Function Ping-GateWays{
    # Run through subnet list and attempt to ping gateways
    foreach ($subnet in $Subnets){
    }
}

Function Add-Content{
    param(
        [string]$Value,
        [string]$Path
    )

    #$time = Get-Date -UFormat "%dd/%MM/%yy %H:%mm:%ss"
    Add-Content -Path $Path -Value $Value
}

# ************************************************
# Program Execution
# ************************************************

# Import module
Import-Module DhcpServer

# Do some work
If ($CheckLeases){
    Check-DhcpServers
}

If ($PingGateways){
    Ping-Gateways
}

# Export results to output Csv
#Export-Csv -InputObject $Results -Path $CsvOut -NoTypeInformation
$results.GetEnumerator() | Export-Csv -Path $CsvOut -NoTypeInformation