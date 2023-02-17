function Get-UninstallKeyPresence {
	param(
		[Parameter (Mandatory=$true)]
		[string]$SearchString,

        [switch]$ReturnPath = $true
	)

    # The actual search
    Function Search-UninstallKeys {
        param (
            [Parameter (Mandatory=$true)]
            [string]$TargetPath,

            [Parameter (Mandatory=$true)]
            [string]$SearchStr
        )

        $Start = Get-Location

        # Can we move to the $TargetPath?
        try {
            Set-Location -Path $TargetPath -ErrorAction Stop
        }
        catch {
            Write-Warning "$TargetPath inaccessible or doesn't exist."
            continue
        }

        # Begin the search
		$keys = (Get-ChildItem).Name
		foreach ($key in $keys) {
			if ((Get-ItemProperty $(($key) -split ('\\'))[-1]).DisplayName -match $SearchStr) {
				if ($ReturnPath) {
					Set-Location $($Start.Path)
                    return "$($key -replace ('HKEY_LOCAL_MACHINE', 'HKLM:'))"
                }
                else {
					Set-Location $($Start.Path)
                    return $true
                }
			}
		}
    }
	
    #Search paths
	$systemUninstallKeys = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\')
    $userUninstallKeys = @('HKU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\', 'HKU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\')
    
    # Mount HKEY_USERS
    $HKUMounted = $false
    try {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
        $HKUMounted = $true
    }
    catch {
        Write-Error "Couldn't mount HKEY_USERS."
    }

    # Check syste hives
	foreach ($k in $systemUninstallKeys){
		$result += Search-UninstallKeys -TargetPath $k -SearchStr $SearchString
	}

    # Check Users hives
    foreach ($k in $userUninstallKeys){
		$result += Search-UninstallKeys -TargetPath $k -SearchStr $SearchString
	}

	#Set-Location $($Start.Path)
    return $result
}