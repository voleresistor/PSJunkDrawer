# ==============
# Define Things
# ==============

# The file we'll be writing to today
$externalLogFile = "\\dxpe.com\dfsa\DFS-Backups\ConsolidationRoots\RootAccess-$(Get-Date -UFormat %d%m%y).csv"
#$externalLogFile = "C:\temp\RootAccess-$(Get-Date -UFormat %d%m%y).csv"
# The log we're querying
$logName = 'Microsoft-Windows-DFSN-Server/Operational'
# The interesting event ID
$logId = 501
# Match <rootname> string
$matchRoot = '(?<=\\)[\w|-]{1,}(?=\\)'
# Match <sharename> string
$matchShare = '(?<=\\)([\w|&|_]{1,}){1,}(?= from client with)'
# Match IP address string. Includes verification of valid addresses
$matchClient = ‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’

# =============
# Collect data
# =============

# Gather the latest log object into a variable for further manipulation
$latestLog = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-DFSN-Server/Operational"; ID=$logId} | Select-Object -First 1

$doMatch = $latestLog.Message -match $matchRoot # Test if the string matches our first regex pattern
$root = $Matches[0] # Get the matched string from the automatic PS variable $Matches

$doMatch = $latestLog.Message -match $matchShare # Test if the string matches our second regex pattern
$share = $Matches[0] # Get the matched string from the automatic PS variable $Matches

$doMatch = $latestLog.Message -match $matchClient # Test if the string matches our third regex pattern
$client = $Matches[0] # Get the matched string from the automatic PS variable $Matches
$client = [System.Net.Dns]::GetHostByAddress($client).HostName # Perform reverse DNS lookup to turn IP address into hostname

$time = $latestLog.TimeCreated # Collect the time the request came in

# ============
# Record Data
# ============

Add-Content -Value "$time,$root,$share,$client" -Path $externalLogFile # Log it all

# ==============
# Sample Output
# ==============

<#
<DD/MM/YY HH:MM:SS>,<OldFileServer>,<OldShareName>,<ClientFQDN>
#>