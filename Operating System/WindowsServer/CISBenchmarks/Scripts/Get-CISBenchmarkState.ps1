function Get-CISBenchmarkState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TargetSettings
    )

    # Try to load the target file
    try {
        [xml]$xmlTargetSettings = Get-Content -Path $TargetSettings
    }
    catch {
        Write-Error $_.Exception.Message
        Write-Warning "Unable to load settings file: $TargetSettings"
        return
    }

    $arrResult = @()
    <#
    [pscustomobject]$objResult = ${
        'Name' = $objSetting.Name
        'Description' = $objSetting.Description
        'Desired' = $objSetting.Value
        'Current' = $currentSetting
        'Pass' = $boolPass
    }
    #>

    foreach ($objSetting in $objTargetSettings) {
        # Assemble our path
        $strKeyPath = "$($objSetting.Hive):\$($objSetting.Key)"

        # Does the key exist?
        if (!(Test-Path -Path $strKeyPath -ErrorAction SilentlyContinue)) {
            $boolPass = $false
        }
        
        $currentSetting = Get-ItemPropertyValue -Path $strKeyPath -Name $($objSetting.Name)
        $boolPass = $currentSetting -eq $objSetting.Value

        [pscustomobject]$objResult = ${
            'Name' = $objSetting.Name
            'Description' = $objSetting.Description
            'Desired' = $objSetting.Value
            'Current' = $currentSetting
            'Pass' = $boolPass
        }
        $arrResult += $objResult
    }
    
    return $arrResult
}