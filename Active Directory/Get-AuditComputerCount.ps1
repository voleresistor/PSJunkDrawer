function Get-AuditComputerCount
{
    <#
    .SYNOPSIS
    Gather simple count metrics for yearly audits.
    
    .DESCRIPTION
    Query AD and SCCM for counts of active computers and AV management status for realy internal audits.
    
    .PARAMETER Domain
    FQDN of target domain or domains. If this is not specified, the local host's domain is assumed.
    
    .PARAMETER CMSiteName
    Three letter CM site name to check for AV management status. If this is not specified, the first mounted CMSite Ps drive is assumed.
    
    .PARAMETER CMModuleLocation
    Path to CM PS module. Default location is default local installation.
    
    .EXAMPLE
    Get-AuditComputercount -Domain example.com
    Get audit data for computers in the example.com domain. Uses the first CMDrive found.

    .EXAMPLE
    Get-AuditComputerCount
    Get audit data for computers in the same domain as the host. Uses the first CMDrive found.
    #>

    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string[]]$Domain = $(Get-WmiObject -Class Win32_ComputerSystem).Domain,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$CMSiteName,

        [Parameter(Mandatory=$false, Position=3)]
        [string]$CMModuleLocation = 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
    )

    begin
    {
        Import-Module -Name $CMModuleLocation # Import config manager module so we can fail up front if that doesn't work

        if ($CMSiteName)
        {
            # If provided, we can use a spcific CMDrive name
            $CmDrive = Get-PSDrive -Name $CMSiteName -PSProvider CMSite
        }
        else
        {
            # Otherwise just search for CMSite type drives and take the first one we see
            $CmDrive = (Get-PSDrive -PSProvider CMSite)[0]
        }

        # Results custom object for data handling
        $results = New-Object -TypeName psobject
        $results | Add-Member -MemberType NoteProperty -Name TotalComputers -Value 0
        $results | Add-Member -MemberType NoteProperty -Name Days14 -Value 0
        $results | Add-Member -MemberType NoteProperty -Name Days30 -Value 0
        $results | Add-Member -MemberType NoteProperty -Name Days60 -Value 0
        $results | Add-Member -MemberType NoteProperty -Name Days90 -Value 0
        $results | Add-Member -MemberType NoteProperty -Name AVManaged -Value 0
        $results | Add-Member -MemberType NoteProperty -Name AVUnmanaged -Value 0
        $results | Add-Member -MemberType NoteProperty -Name AVToBeInstalled -Value 0
        $results | Add-Member -MemberType NoteProperty -Name AVUnknown -Value 0
        $results | Add-Member -MemberType NoteProperty -Name AVFailed -Value 0

        # We're only looking at recently active computers to gather AV stats
        $computersUnder14 = @()
    }
    process
    {
        foreach ($dom in $Domain)
        {
            # We don't care about disabled computer objects
            $activeComputers = Get-ADComputer -Filter { Enabled -eq 'True' } -Server $dom -Properties LastLogonDate
            $results.TotalComputers += $activeComputers.Count

            foreach ($computer in $activeComputers)
            {
                #[datetime]$lastLogonDate = $computer.LastLogonDate
                if ([datetime]$($computer.LastLogonDate) -gt $((Get-Date).AddDays(-14)))
                {
                    $results.Days14++
                    $computersUnder14 += $computer.Name
                }

                if([datetime]$($computer.LastLogonDate) -gt $((Get-Date).AddDays(-30)))
                {
                    $results.Days30++
                }

                if([datetime]$($computer.LastLogonDate) -gt $((Get-Date).AddDays(-60)))
                {
                    $results.Days60++
                }

                if([datetime]$($computer.LastLogonDate) -gt $((Get-Date).AddDays(-90)))
                {
                    $results.Days90++
                }
            }
        }

        # Get AV status of active computers
        $current = Get-Location
        Set-Location -Path "$($CmDrive.Name)`:\"
        foreach ($device in $computersUnder14)
        {
            $state = (Get-CMDevice -Name $device).EPDeploymentState
            switch($state)
            {
                1 {$results.AVUnmanaged++}
                2 {$results.AVToBeInstalled++}
                3 {$results.AVManaged++}
                4 {$results.AVFailed++}
                default {$results.AVUnknown++}
            }
        }
    }
    end
    {
        Set-Location -Path $($current.Path)
        Remove-Module -Name ConfigurationManager
        return $results
    }
}