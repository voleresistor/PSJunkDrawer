function Start-GpoComparison
{
    <#
    .SYNOPSIS
    Compare GPOs between a source and comparison server.
    
    .DESCRIPTION
    Generate comparison of several attributes between two domain controllers. Can help spot inconsistencies in replication. Requires Get-ComputerDomain function. This function can take a long time to run if the source DC contains a large number of policy objects.
    
    .PARAMETER SourceDC
    Domain controller to pull policy list from. This should be the known good server.
    
    .PARAMETER CompareDC
    Domain controller to compare to the source. This is the server suspected of issues.
    
    .EXAMPLE
    Start-GpoComparison -SourceDC dc01 -CompareDC dc03
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$SourceDC,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$CompareDC
    )

    # Get FQDNs for both computers and gather policies for source
    $sdc = Get-ComputerDomain -ComputerName $SourceDC
    $cdc = Get-ComputerDomain -ComputerName $CompareDC
    if ($sdc -and $cdc)
    {
        $policies = Get-ChildItem -Path "\\$($sdc.Name).$($sdc.Domain)\SYSVOL\$($sdc.Domain)\Policies"
    }
    else
    {
        Write-Error "Couldn't look up FQDN for one of the targets."
        exit
    }

    $Policy_Array = @()
    foreach ($pol in $policies)
    {
        if ($($pol.Name) -eq "PolicyDefinitions")
        {
            continue
        }

        $polname = $pol.Name -replace ('{','') -replace ('}','')

        $polentry = New-Object -TypeName psobject
        $polentry | Add-Member -MemberType NoteProperty -Name "PolicyGUID" -Value $polname
        $polentry | Add-Member -MemberType NoteProperty -Name "PolicyName" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).DisplayName

        $polentry | Add-Member -MemberType NoteProperty -Name "SourceStatus" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).GpoStatus
        $polentry | Add-Member -MemberType NoteProperty -Name "SourcePolicyDate" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).ModificationTime
        $polentry | Add-Member -MemberType NoteProperty -Name "SourceDSVer" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).Computer.DSVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "SourceSysvolVer" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).Computer.SysvolVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "SourceUserDSVer" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).User.DSVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "SourceUserSysvolVer" -Value $(Get-GPO -Guid $polname -Server $($sdc.Name) -Domain $($sdc.Domain) -ErrorAction SilentlyContinue).User.SysvolVersion

        $polentry | Add-Member -MemberType NoteProperty -Name "CompareStatus" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).GpoStatus
        $polentry | Add-Member -MemberType NoteProperty -Name "ComparePolicyDate" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).ModificationTime
        $polentry | Add-Member -MemberType NoteProperty -Name "CompareDSVer" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).Computer.DSVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "CompareSysvolVer" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).Computer.SysvolVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "CompareUserDSVer" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).User.DSVersion
        $polentry | Add-Member -MemberType NoteProperty -Name "CompareUserSysvolVer" -Value $(Get-GPO -Guid $polname -Server $($cdc.Name) -Domain $($cdc.Domain) -ErrorAction SilentlyContinue).User.SysvolVersion

        $Policy_Array += $polentry
    }

    return $Policy_Array
}