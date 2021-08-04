function Get-PufferLogins {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$UserName
    )

    # Find the latest NPS log
    $NpsLogPath = "$env:windir\System32\LogFiles"
    $LatestLog = Get-ChildItem -Path $NpsLogPath -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

    # Get XML data from NPS log
    [xml[]]$NpsLogResult = Get-Content -Path $($LatestLog.FullName) | Select-String $UserName

    # Get log objects from the MFA log
    $MfaLog = 'Microsoft-AzureMfa-AuthZ'
    $MfaLogResult = Get-WinEvent -ProviderName $MfaLog | Where-Object -FilterScript {$_.Message -like "*$UserName*"}

    # Pack it all into a hash and give it back
    $MyResults = @{
        'NPS_XML' = $NpsLogResult;
        'MFA_Events' = $MfaLogResult
    }
    return $MyResults
}