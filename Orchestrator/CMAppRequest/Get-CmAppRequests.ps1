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
    $tmp = @()

    $SiteCode = (gwmi -ComputerName $SiteServer -Namespace root\SMS -Class "SMS_ProviderLocation").SiteCode

    $APPAPR = Invoke-Command -ComputerName $siteServer -Credential $mycreds -ScriptBlock {
        import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
        $PSD = Get-PSDrive -PSProvider CMSite
        if (!$PSD)
        {
            try
            {
                New-PSDrive -Name $($args[1]) -PSProvider CMSite -Root $($args[0])
                $PSD = Get-PSDrive -PSProvider CMSite
            }
            catch
            {
                return "FAILED setting PSDrive"
            }
        }
        
        Set-Location -Path "$PSD`:\"
        $APPAPR = Get-CMApprovalRequest | Where-Object {$_.LastModifiedDate -gt ($(Get-Date).AddDays(-3))}
        new-object pscustomobject -property @{
            RGUID = $APPAPR.RequestGuid
        }
    } -Args $siteServer,$SiteCode

    $RGUID = $APPAPR.RGUID

    foreach ($appr in $RGUID) {
        if ($appr -ne $null)
        {
            $appAprGUID += $appr
        }
    }

    return $appAprGUID
}