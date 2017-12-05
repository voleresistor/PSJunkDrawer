function Get-CmAppRequests
{
    param
    (
        [Parameter(Mandatory=$true)]
        $Password,

        [Parameter(Mandatory=$true)]
        $UserName,

        [Parameter(Mandatory=$true)]
        $SiteServer
    )

    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
    $appAprGUID=@()
    $SiteCode = (gwmi -ComputerName $SiteServer -Namespace root\SMS -Class "SMS_ProviderLocation").SiteCode
    $APPAPR = Invoke-Command -ComputerName $siteServer -Credential $mycreds -ScriptBlock {
        import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
        New-PSDrive -Name $($args[0]) -PSProvider CMSite -Root $($args[1]) | Out-Null
        Set-Location -Path "$($args[0]):\"
        $APPAPR = Get-CMApprovalRequest | Where-Object {$_.LastModifiedDate -gt ($(Get-Date).AddDays(-3))}
        new-object pscustomobject -property @{
            RGUID = $APPAPR.RequestGuid
        }
    } -Args $SiteCode,$siteServer
    $RGUID = $APPAPR.RGUID
    foreach ($appr in $RGUID) {
        if ($appr -ne $null)
        {
            $appAprGUID += $appr
        }
    }
    return $appAprGUID  
}