function Get-SecurityPolicyState {
    [CmdletBinding()]
    param ()

    # Define the expected settings
    $DesiredConfig = @{
        'MinimumPasswordAge' = 1
        'MaximumPasswordAge' = 60
        'MinimumPasswordLength' = 14
        'PasswordComplexity' = 1
        'PasswordHistorySize' = 24
        'ClearTextPassword' = 0
    }

    # Temp files to export settings and logs
    $TmpFile = New-TemporaryFile
    $JunkFile = New-TemporaryFile
    $LogFile = New-TemporaryFile

    # Export current settings
    $strArgsList = "/export /db secedit.sdb /cfg $($TmpFile.FullName) /log $($LogFile.FullName) /areas SECURITYPOLICY"
    Start-Process -FilePath 'secedit.exe' -ArgumentList $strArgsList -NoNewWindow -Wait -RedirectStandardOutput $($JunkFile.FullName)

    # Check settings
    $CurrentConfig = Get-Content -Path $($TmpFile.FullName)
    $RemediationNeeded = $false
    foreach ($setting in $DesiredConfig.Keys) {
        $desiredSetting = $DesiredConfig[$setting]
        $currentSetting = (($CurrentConfig | Select-String -Pattern $setting) -split(' = '))[1]

        Write-Verbose "Setting Name: $setting"
        Write-Verbose "Desired Setting: $desiredSetting"
        Write-Verbose "Current Setting: $currentSetting"

        if ($desiredSetting -ne $currentSetting) {
            #Write-Warning "$setting is $currentSetting and should be $desiredSetting"
            $RemediationNeeded = $true
        }
    }

    # Clean up the settings file
    Remove-Item -Path $($TmpFile.FullName) -Force
    Remove-Item -Path $($JunkFile.FullName) -Force
    
    # Finish
    return $RemediationNeeded
}