$password = "\`d.T.~Vb/{24737E7D-4206-4424-A2B0-E0BE4BAE0AFD}\`d.T.~Vb/"
$userName = "\`d.T.~Vb/{9212B15A-4A52-4E55-B9AC-DB1F3F11FEDF}\`d.T.~Vb/"
$siteServer = "\`d.T.~Vb/{61DFFDD1-F507-4125-813F-BA8C70A77BA1}\`d.T.~Vb/"
$execFrequency = \`d.T.~Vb/{F05EEB42-5483-4128-872C-C408757EE342}\`d.T.~Vb/
$secondEmail = \`d.T.~Vb/{E199B715-95D1-4689-BD07-F17FF803CDB8}\`d.T.~Vb/
$deny = \`d.T.~Vb/{A977F4DC-9E7C-47C7-BF38-7FA1F9F864C7}\`d.T.~Vb/

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)

$APPAPR = Invoke-Command -ComputerName $siteServer -Credential $mycreds -ScriptBlock {

    &"$env:windir\syswow64\windowspowershell\v1.0\powershell.exe" -noninteractive -noprofile {
        import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
        $PSD = Get-PSDrive -PSProvider CMSite
        CD "$($PSD):"
        Get-CMApprovalRequest -RequestGuid "\`d.T.~Ed/{8C249CFB-02B0-4C2E-9EDC-36B304AE17A6}.App Request GUID\`d.T.~Ed/"
    }
}

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