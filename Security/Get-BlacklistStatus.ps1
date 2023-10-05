# blacklistcheck.ps1 - PowerShell script to check
# an IP address blacklist status
# 
# Follow me on Twitter: @Jan_Reilink
# 
# Steps:
# 1. IPv4 IP address input from the command-line:
#    .\blacklistcheck.ps1 1.2.3.4
# 2. reverse the IP address: 1.2.3.4 becomes 4.3.2.1
# 3. append the blacklist zone, e.g .cbl.abuseat.org. 
#    to the reversed IP address
# 4. perform a DNS lookup
# 5. print out the result

param (
  [Parameter(Mandatory)]
  [string]$Address = $(throw "ip is required.")
 )

# Project Honey Pot API-key, create a free account 
# and get yours @ 
# https://www.projecthoneypot.org/create_account.php
#[static]$httpBL = "[my-API-key]"

# If address is not an IP address, perform a DNS lookup and replace the address with the IP
if (![bool]($Address -as [ipaddress])) {
    try {
        $Address = (Resolve-DnsName -Name $Address -ErrorAction SilentlyContinue).IPAddress
    }
    catch
    {
        Exit
    }
}
 
# Reverse IP address stored in $Address, let's hussle 
# those IP octets around a bit
$ipParts = $Address.Split('.')
[array]::Reverse($ipParts)
$ipParts = [string]::Join('.', $ipParts)

# An array of blacklists to perform checks on
# You can add your own blacklists to this list
$blacklists = #"dnsbl.httpbl.org", `
	"cbl.abuseat.org", `
	"dnsbl.sorbs.net", `
	"bl.spamcop.net", `
	"zen.spamhaus.org", `
	"b.barracudacentral.org", `
	"bad.psky.me"

foreach ( $blacklist in $blacklists ) {
	if ( $blacklist -contains "dnsbl.httpbl.org" ) {
		# Add your httpBL API-key from Project Honey Pot
		$lookupAddress = $httpBL + "." + $ipParts + ".dnsbl.httpbl.org."
	}
	else {
		$lookupAddress = $ipParts + ".$blacklist."
	}
	try {
		[System.Net.Dns]::GetHostEntry($lookupAddress) | select-object HostName,AddressList
	}
	catch {
		# The try{} catch{} is needed to catch DNS lookup 
		# errors when an IP address is not blacklisted.
		# Yes, this is annoying
		#Write-Host "No blacklisting for $Address found in $blacklist"
	}
}