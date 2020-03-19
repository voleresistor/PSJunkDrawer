function Set-LockScreen {
    <#
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ImagePath
    )

    if (Test-Path -Path $ImagePath) {
        # Necessary keys and values
        $cdnKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        $cdnVal = @{
            'RotatingLockScreenEnabled' = 0;
            'RotatingLockScreenOverlayEnabled' = 0
        }

        $crtKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen\Creative'
        $crtVal = @{
            'LockImageFlags' = 0;
            'PortraitAssetPath' = "$ImagePath";
            'LandscapeAssetPath' = "$ImagePath";
            'HotspotImageFolderPath' = "$ImagePath"
        }

        # Update lock screen info
        try {
            if (!(Test-Path -Path $cdnKey -ErrorAction SilentlyContinue)) {
                New-Item -Path $cdnKey -Force
            }
        
            foreach ($v in $($cdnVal.Keys)) {
                Set-ItemProperty -Path $cdnKey -Name $v -Value $($cdnVal[$v])
            }
        
            if (!(Test-Path -Path $crtKey -ErrorAction SilentlyContinue)) {
                New-Item -Path $crtKey -Force
            }
        
            foreach ($v in $($crtVal.Keys)) {
                Set-ItemProperty -Path $crtKey -Name $v -Value $($crtVal[$v])
            }
        }
        catch {
            Write-Warning $_.Exception.Message
        }
    }
}

Set-LockScreen -ImagePath "$($env:systemroot)\XJTAssets\ExpressLock01.png"