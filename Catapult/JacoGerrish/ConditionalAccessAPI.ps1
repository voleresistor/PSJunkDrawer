#New-StoredCredential -Comment 'Azure Creds' -Credentials (Get-Credential "5e57b7a5-3d7f-4787-9928-476860c59c39") -Target 'Azure Creds' | Out-Null

function Invoke-GraphAPIToggle {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('enabled','disabled')]
        [string]$Action,

        [Parameter(Mandatory=$false)]
        [string]$PolicyId     = "5e57b7a5-3d7f-4787-9928-476860c59c39",

        [Parameter(Mandatory=$false)]
        [string]$CredentialTarget = 'Azure Creds',

        [Parameter(Mandatory=$false)]
        [string]$TenantDomain = "puffer.onmicrosoft.com",

        [Parameter(Mandatory=$false)]
        [string]$LoginUrl     = "https://login.microsoft.com",

        [Parameter(Mandatory=$false)]
        [string]$Resource     = "https://graph.microsoft.com"
    )

    Import-Module CredentialManager

    $Credentials = Get-StoredCredential -Target $CredentialTarget
    $UserAgent    = "$TenantDomain / Time Restriction Workflow Agent 1.0"

    $body         = @{grant_type="client_credentials";Resource=$Resource;client_id=$Credentials.UserName;client_secret=$Credentials.GetNetworkCredential().Password}
    $oauth        = Invoke-RestMethod -Method Post -Uri $LoginUrl/$TenantDomain/oauth2/token?api-version=1.0 -Body $body

    $oauth | select *

    if ($oauth.access_token -ne $null){

    $headerParams = @{
        "Content-Type" = "application/json";
        'Authorization'="$($oauth.token_type) $($oauth.access_token)";
        }

    $Api = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$PolicyId"

    try{
        
        $Target = Invoke-RestMethod -Method Get -Uri $Api -Headers $headerParams -UserAgent $UserAgent

        if($Target.state -notlike $Action){
            $params = @{"state"=$Action}
            Invoke-RestMethod -Method Patch -Uri $Api -Body $($params|ConvertTo-Json) -Headers $headerParams -UserAgent $UserAgent
            Write-Host -ForegroundColor Green "success"
        }else{
            throw "Error: cannot $($Action.Substring(0,$Action.Length-1)) policy, it is already $($Action)"
        }

    }catch{
        $_.Exception
    }

    }else {
    throw "Error: Unable to get API token"
    }
}