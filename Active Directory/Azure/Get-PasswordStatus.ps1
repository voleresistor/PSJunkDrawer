$TenantID = "Enter Tenant ID"
$ApplicationID = "Enter Application ID"
$AppSecret = 'Enter Secret Value'

$PasswordExpirationDays = 90

$WindirTemp = Join-Path $Env:Windir -Childpath "Temp"
$UserTemp = $Env:Temp
$UserContext = [Security.Principal.WindowsIdentity]::GetCurrent()

Switch ($UserContext) {
    { $PSItem.Name -Match       "System"    } { Write-Output "Running as System"  ; $Temp =  $UserTemp   }
    { $PSItem.Name -NotMatch    "System"    } { Write-Output "Not running System" ; $Temp =  $WindirTemp }
    Default { Write-Output "Could not translate Usercontext" }
}

$logfilename = "PasswordNotificationDS"
$logfile = Join-Path $Temp -Childpath "$logfilename.log"

$LogfileSizeMax = 100

##############################
## Functions
##############################

Function Get-MSGraphAuthToken {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true)]
        [pscredential]$Credential,
        [parameter(Mandatory = $true)]
        [string]$tenantID
    )
    
    #Get token
    $AuthUri = "https://login.microsoftonline.com/$TenantID/oauth2/token"
    $Resource = 'graph.microsoft.com'
    $AuthBody = "grant_type=client_credentials&client_id=$($credential.UserName)&client_secret=$($credential.GetNetworkCredential().Password)&resource=https%3A%2F%2F$Resource%2F"

    $Response = Invoke-RestMethod -Method Post -Uri $AuthUri -Body $AuthBody
    If ($Response.access_token) {
        return $Response.access_token
    }
    Else {
        Throw "Authentication failed"
    }
}
Function Invoke-MSGraphQuery {
    [CmdletBinding(DefaultParametersetname = "Default")]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
        [string]$URI,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Refresh')]
        [string]$Body,

        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
        [string]$token,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Refresh')]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$method = "GET",
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Refresh')]
        [switch]$recursive,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
        [switch]$tokenrefresh,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
        [pscredential]$credential,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
        [string]$tenantID
    )
    $authHeader = @{
        'Accept'        = 'application/json'
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $Token"
    }
    
    [array]$returnvalue = $()
    Try {
        If ($body) {
            $Response = Invoke-RestMethod -Uri $URI -Headers $authHeader -Body $Body -Method $method -ErrorAction Stop
        }
        Else {
            $Response = Invoke-RestMethod -Uri $URI -Headers $authHeader -Method $method -ErrorAction Stop
        }
    }
    Catch {
        If (($Error[0].ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).error.Message -eq 'Access token has expired.' -and $tokenrefresh) {
            $token = Get-MSGraphAuthToken -credential $credential -tenantID $TenantID

            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = $Token
            }
            $returnvalue = $()
            If ($body) {
                $Response = Invoke-RestMethod -Uri $URI -Headers $authHeader -Body $Body -Method $method -ErrorAction Stop
            }
            Else {
                $Response = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method $method
            }
        }
        Else {
            Throw $_
        }
    }

    $returnvalue += $Response
    If (-not $recursive -and $Response.'@odata.nextLink') {
        Write-Warning "Query contains more data, use recursive to get all!"
        Start-Sleep 1
    }
    ElseIf ($recursive -and $Response.'@odata.nextLink') {
        If ($PSCmdlet.ParameterSetName -eq 'default') {
            If ($body) {
                $returnvalue += Invoke-MSGraphQuery -URI $Response.'@odata.nextLink' -token $token -body $body -method $method -recursive -ErrorAction SilentlyContinue
            }
            Else {
                $returnvalue += Invoke-MSGraphQuery -URI $Response.'@odata.nextLink' -token $token -method $method -recursive -ErrorAction SilentlyContinue
            }
        }
        Else {
            If ($body) {
                $returnvalue += Invoke-MSGraphQuery -URI $Response.'@odata.nextLink' -token $token -body $body -method $method -recursive -tokenrefresh -credential $credential -tenantID $TenantID -ErrorAction SilentlyContinue
            }
            Else {
                $returnvalue += Invoke-MSGraphQuery -URI $Response.'@odata.nextLink' -token $token -method $method -recursive -tokenrefresh -credential $credential -tenantID $TenantID -ErrorAction SilentlyContinue
            }
        }
    }
    Return $returnvalue
}

##############################
## Scriptstart
##############################

If ($logfilename) {
    If (((Get-Item -ErrorAction SilentlyContinue $logfile).length / 1MB) -gt $LogfileSizeMax) { Remove-Item $logfile -Force }
    Start-Transcript $logfile -Append | Out-Null
    Get-Date
}

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Try {
    $LoggedSID = Get-WmiObject -Class win32_computersystem | Select-Object -ExpandProperty Username | ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }
}
Catch {
    Write-Error -Message "Failed to gather SID for current user" -ErrorAction Stop
}

Try {
    $CurrentAzureADUser = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache\$LoggedSID\IdentityCache\$LoggedSID" -Name UserName).UserName
}
Catch {
    Write-Error -Message "Failed to gather CurrentAzureADUser" -ErrorAction Stop
}

If (!($CurrentAzureADUser)) { Write-Output "Failed to gather CurrentAzureADUser, Exiting" ; Exit 0 }

$Credential = New-Object System.Management.Automation.PSCredential($ApplicationID, (ConvertTo-SecureString $AppSecret -AsPlainText -Force))
$Token = Get-MSGraphAuthToken -credential $Credential -TenantID $TenantID

$UserName   = $CurrentAzureADUser

$resourceURL = "https://graph.microsoft.com/v1.0/users/$UserName`?`$select=userprincipalname,lastPasswordChangeDateTime"
$User = Invoke-MSGraphQuery -method GET -URI $resourceURL -token $token

#$Date = Get-Date -format "yyyy-MM-dd hh:mm:ss"
[datetime]$lastpasswordChange = $User.lastPasswordChangeDateTime -replace "T", " " -replace "Z",""

$PasswordExpirationDate = ($lastpasswordChange).AddDays($PasswordExpirationDays)

$StartDate  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$TimeSpan = New-Timespan -Start $StartDate -End $PasswordExpirationDate

# Create a local store for exiration data if necessary
if ((Test-Path -Path 'HKCU:\Software\Puffer\ApplicationInstallation\PasswordReset') -eq $false) {
    New-Item 'HKCU:\Software\Puffer\ApplicationInstallation\PasswordReset' -ItemType Directory -Force
}

# Write days til expiration to a registry value
Set-ItemProperty -Path HKCU:\Software\Puffer\ApplicationInstallation\PasswordReset -Name DaysUntilExpiration -Value $($TimeSpan.Days) -Type String -Force
Set-ItemProperty -Path HKCU:\Software\Puffer\ApplicationInstallation\PasswordReset -Name LastCheck -Value $(Get-Date) -Type String -Force

If (($TimeSpan.Days -le 10) -and ($TimeSpan.Days -ge -5)) {
    Write-Output "Password Expires after $($TimeSpan.Days) days"
    Exit 1
}

If ($logfilename) {
    Stop-Transcript | Out-Null
}

Exit 0