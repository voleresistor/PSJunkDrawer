function Invoke-ADReplication {
    [CmdletBinding(SupportsShouldProcess=$true)]
    <#
    .SYNOPSIS
    Invoke replication in a given Active Driectory domain.

    .DESCRIPTION
    Recalculate inbound topology and invoke replication for each domain controller discovered.

    .PARAMETER Domain
    The domain against which to invoke replication. Defaults to %userdnsdomain%.

    .PARAMETER ShowSummary
    Calculate a summary of the latest replication following the invoke procedure.
    #>

    param (
        [Parameter(Mandatory=$false,Position=1)]
        [string]$Domain = $env:userdnsdomain,

        [Parameter(Mandatory=$false)]
        [switch]$ShowSummary
    )

    begin {
        # Try load ActiveDirectory module before anything else. No reason to continue if we can't query the domain
        try {
            Write-Verbose 'Importing ActiveDirectory module.'
            Import-Module -Name ActiveDirectory -Cmdlet 'Get-ADComputer'
        }
        catch {
            Write-Error "Couldn't load module ActiveDirectory. Do you have Active Directory RSAT tools installed?"
            Write-Error $_.Exception.Message
            break
        }

        # Verify repadmin program is present
        Write-Verbose "Verifyng that repadmin program is present."
        $repadmin = "$env:systemroot\System32\repadmin.exe"
        $repadminTest = Test-Path -Path $repadmin -ErrorAction Stop
        if ($repadminTest -eq $false) {
            Write-Error "Repadmin.exe not found. Do you have DFS RSAT tools installed?"
            Write-Error $_.Exception.Message
            break
        }
        Write-Verbose "Repadmin found in expected location: $repadmin"

        # Build SearchBase from domain name
        Write-Verbose "Splitting domain name: $Domain"
        $SplitDomain = $Domain.Split('.')
        Write-Verbose "Split domain into $($SplitDomain.Count) parts:"
        foreach ($part in $SplitDomain) {
            Write-Verbose $part
        }

        Write-Verbose "Generating SearchBase."
        $SearchBase = 'OU=Domain Controllers'
        if ($SplitDomain.Length -gt 1) {
            foreach ($part in $SplitDomain) {
                Write-Verbose "Adding $part to SearchBase."
                $SearchBase += ",DC=$part"
            }
        }
        else {
            # If only NetBIOS name was supplied, assume TLD is com
            Write-Verbose "Got NetBIOS domain name. Assuming COM for TLD."
            $SearchBase += ",DC=$SplitDomain,DC=com"
        }
        Write-Verbose "Final SearchBase: $SearchBase"

        # Query a list of domain controllers
        Write-Verbose "Attempting to get a list of domain controllers in $Domain."
        try {
            $DCList = Get-ADComputer -Filter {Enabled -eq $true} -SearchBase $SearchBase
        }
        catch {
            Write-Warning 'Failed to query domain:'
            Write-Warning $_.Exception.Message
        }
        Write-Verbose "Found $($DCList.Count) domain controllers:"
        foreach ($DC in $DCLIst) {
            Write-Verbose $DC.DnsHostName
        }
    }
    process {
        foreach ($DC in $DCList) {
            # Recalculate inbound replication topology
            # Wait three seconds after each action to avoid queueing up too much at once
            if ($PSCmdlet.ShouldProcess($DC, 'Recalculate inbound replication topology')) {
                Start-Process -FilePath $repadmin -ArgumentList "/kcc $($DC.DnsHostName)" -NoNewWindow -Wait
                Start-Sleep -Seconds 3
            }
        }

        foreach ($DC in $DCList) {
            # Enforce replication
            if ($PSCmdlet.ShouldProcess($DC, 'Invoke replication with all inbound partners')) {
                Start-Process -FilePath $repadmin -ArgumentList "/syncall /A /e $($DC.DnsHostName)" -NoNewWindow -Wait
                Start-Sleep -Seconds 3
            }
        }

        if ($ShowSummary) {
            # Run replsummary
            if ($PSCmdlet.ShouldProcess($Domain, 'Show replication summary')) {
                Start-Process -FilePath $repadmin -ArgumentList "/replsummary" -NoNewWindow -Wait
            }
        }
    }
}