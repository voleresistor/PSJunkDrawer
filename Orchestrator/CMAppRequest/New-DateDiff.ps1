$password = "\`d.T.~Vb/{24737E7D-4206-4424-A2B0-E0BE4BAE0AFD}\`d.T.~Vb/"
$userName = "\`d.T.~Vb/{9212B15A-4A52-4E55-B9AC-DB1F3F11FEDF}\`d.T.~Vb/"
$siteServer = "housccm03.dxpe.com"
$execFrequency = 5
$secondEmail = 3600
$deny = 7200

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
$appAprGUID=@()
$SiteCode = (gwmi -ComputerName $SiteServer -Namespace root\SMS -Class "SMS_ProviderLocation").SiteCode
$APPAPR = Invoke-Command -ComputerName $siteServer -Credential $mycreds -ScriptBlock {
    import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
    New-PSDrive -Name $($args[0]) -PSProvider CMSite -Root $($args[1]) | Out-Null
    Set-Location "$($args[0]):\"
    Get-CMApprovalRequest -RequestGuid "1FB4692B-CEA9-4C05-917D-C7FCCC5D6968" #Filled by data from previous ruinbook steps
} -ArgumentList $SiteCode,$siteServer

$appName = $APPAPR.Application

#$history = $APPAPR.RequestHistory | Select-Object -First 1
$currentComment = $APPAPR.Comments
$currentAdmin = $APPAPR.LastModifiedBy
$currentTime = $APPAPR.LastModifiedDate
$currentState = $APPAPR.CurrentState

$requestUser = $APPAPR.User
$userSam = ($requestUser -split '\\')[1]

#$date = $APPAPR.LastModifiedDate
$today = get-date
$action = "NotDoingShit"

if ($currentState -eq 1){
    if (($currentTime -lt $today) -and ($currentTime -gt $today.AddMinutes(-$execFrequency))){
        $action = "FirstEmail"
    }
    
    if (($currentTime -lt $today.AddMinutes(-$secondEmail)) -and ($currentTime -gt $today.AddMinutes(-($secondEmail + $execFrequency)))) {
        $action = "SecondEmail"
    }

    if (($currentTime -lt $today.AddMinutes(-$deny)) -and ($requestState -eq 1)) {
    $action = "AutoDeny"
    }
}
elseif ($currentState -eq 2){
    if (($currentTime -lt $today.AddMinutes(-$deny)) -and ($currentState -eq 1)){
        $action = "CancelEmail"
    }
}
elseif ($currentState -eq 3){
    if (($currentTime -gt $today.AddMinutes(-$execFrequency)) -and ($currentTime -lt $today)) {
        $action = "DenialEmail"
    }
}
elseif ($currentState -eq 4){
    if (($currentTime -gt $today.AddMinutes(-$execFrequency)) -and ($currentTime -lt $today)) {
        $action = "ApprovalEmail"
    }
}

Add-Content -Value "$(Get-Date) - $appName - $currentTime - $action" -Path C:\Temp\actions.log