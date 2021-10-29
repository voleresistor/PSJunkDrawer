function Remove-SkypeStuff {
	$result = @{
		'Success' = $true;
		'Failures' = @()
	}
	$files = @(); ls -Directory -Path 'C:\Program Files\Microsoft Office' | %{ if ($_.Name -ne 'Updates'){ $files += ls -Recurse -Include "*skype*" -Path $_.FullName } }
	$regkey = @()
	$regKey +=  ls 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' | %{ if ($_.GetValue('DisplayName') -eq 'Skype for Business 2016 - en-us'){ $_.Name } }
	$regKey += ls -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\' | %{ if ($_.GetValue('DisplayName') -eq 'Skype for Business 2016 - en-us'){ $_.Name } }
	
	foreach ($k in $regKey) {
		try {
			Remove-Item -Path $($k -replace("HKEY_LOCAL_MACHINE", 'hklm:')) -Force -Recurse -ErrorAction Stop
		}
		catch {
			$result['Success'] = $false
			$result['Failures'] += $k
		}
	}
	foreach ($f in $files) {
		try {
			Remove-Item -Path $f.FullName -Force -Recurse -ErrorAction Stop
		}
		catch {
			$result['Success'] = $false
			$result['Failures'] += $f.FullName
		}
	}
	return $result
}
