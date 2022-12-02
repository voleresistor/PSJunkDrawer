function Set-SecurityPolicyState {
    [CmdletBinding(SupportsShouldProcess=$true)]
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
    $NewFile = New-TemporaryFile
    $JunkFile = New-TemporaryFile
    $LogFile = New-TemporaryFile

    # Export current settings
    $strArgsList = "/export /db secedit.sdb /cfg $($TmpFile.FullName) /log $($LogFile.FullName) /areas SECURITYPOLICY"
    Start-Process -FilePath 'secedit.exe' -ArgumentList $strArgsList -NoNewWindow -Wait -RedirectStandardOutput $($JunkFile.FullName)

    # Build new config file
    $CurrentConfig = Get-Content -Path $($TmpFile.FullName)
    foreach ($line in $CurrentConfig) {
        if ($line -match " = ") {
            $thisSetting = (($line) -split(' = '))[0]
            Write-Verbose "Setting Name: $thisSetting"

            if ($DesiredConfig.Keys -contains $thisSetting) {
                $desiredSetting = $($DesiredConfig[$thisSetting])
                Write-Verbose "Update setting $thisSetting to $desiredSetting"
                $line = "$thisSetting = $desiredSetting"
            }
        }

        Add-Content -Value $line -Path $($NewFile.FullName)
    }

    # Import new file
    $strArgsList = "/configure /db secedit.sdb /cfg $($NewFile.FullName) /log $($LogFile.FullName) /areas SECURITYPOLICY"
    if ($PSCmdlet.ShouldProcess("secedit.exe $strArgsList")) {
        Start-Process -FilePath 'secedit.exe' -ArgumentList $strArgsList -NoNewWindow -Wait -RedirectStandardOutput $($JunkFile.FullName)
    }

    # Clean up the settings file
    Remove-Item -Path $($TmpFile.FullName) -Force
    Remove-Item -Path $($JunkFile.FullName) -Force
    Remove-Item -Path $($NewFile.FullName) -Force
    
    # Finish
    #return $($NewFile.FullName)
}