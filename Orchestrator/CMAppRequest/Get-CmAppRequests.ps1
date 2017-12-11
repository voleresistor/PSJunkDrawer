<#
    Request States:
    1 - Requested
    2 - Canceled
    3 - Denied
    4 - Approved
#>
function Get-CmAppRequests
{
    <#
    .SYNOPSIS
    Gather unhandled application requests from a CM server.
    
    .PARAMETER Password
    Plaintext password. This script is written for Orchestrator with the intent of accepting the password from a hashed variable.
    
    .PARAMETER UserName
    Plaintext username.
    
    .PARAMETER SiteServer
    FQDN of site server.
    #>
    param
    (
        [Parameter(Mandatory=$true)]
        $Password,

        [Parameter(Mandatory=$true)]
        $UserName,

        [Parameter(Mandatory=$true)]
        $SiteServer,

        [Parameter(Mandatory=$false)]
        $MaxAgeHours = 73
    )

    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
    $SiteCode = (Get-WmiObject -ComputerName $SiteServer -Namespace 'root\SMS' -Class "SMS_ProviderLocation" -Credential $mycreds).SiteCode
    $requests = Get-WmiObject -Class 'SMS_UserApplicationRequest' -Namespace "root\sms\site_$SiteCode" -ComputerName $SiteServer -Credential $mycreds #| Where-Object {$_.LastModifiedDate -gt $((Get-Date).AddHours(-73))}
    <#$requests = invoke-command -ComputerName $SiteServer -Credential $mycreds -ScriptBlock {
        Get-WmiObject -Class 'SMS_UserApplicationRequest' -Namespace "root\sms\site_$($args[0])" -ComputerName $($args[1])
    } -ArgumentList $SiteCode,$SiteServer#>
    $appAprGUID = @()
    foreach ($r in $requests)
    {
        $date,$null = $r.LastModifiedDate -split ('\.')
        $date = [datetime]::ParseExact($date, 'yyyyMMddHHmmss', $null)
        if ($date -gt $((Get-Date).AddHours(-$MaxAgeHours)))
        {
            $appAprGUID += $r.RequestGuid
        }
    }
    return $appAprGUID  
}