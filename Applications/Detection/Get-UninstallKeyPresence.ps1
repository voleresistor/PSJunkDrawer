function Get-UninstallKeyPresence {
	param(
		[Parameter (Mandatory=$true)]
		[string]$SearchString,

        [switch]$ReturnPath
	)
	$Start = Get-Location
	$uninstallKeys = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\')
	foreach ($k in $uninstallKeys){
		Set-Location -Path $k
		$keys = (Get-ChildItem).Name
		foreach ($key in $keys) {
			if ((Get-ItemProperty $(($key) -split ('\\'))[-1]).DisplayName -match $SearchString) {
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
	Set-Location $($Start.Path)
}