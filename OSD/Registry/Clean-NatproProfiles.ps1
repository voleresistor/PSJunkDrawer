$NPProfiles = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' | Where-Object {$_.Name -like '*S-1-5-21-2550688893-1842628442-4030347136*'}
if ($($NPProfiles.Count) -gt 0)
{
	$LogPath = "$env:SystemRoot\Temp\NPProfileClean.log"
	foreach ($NPProfile in $NPProfiles)
	{
		$ProfilePath = $NPProfile.Name -replace ('HKEY_LOCAL_MACHINE', 'HKLM:')
		Remove-Item -Path $ProfilePath -Recurse -Force
		if (!(Test-Path -Path $ProfilePath))
		{
			$TimeStamp = Get-Date -UFormat "%m/%d/%y - %H:%M:%S"
			Add-Content -Path $LogPath -Value "$TimeStamp> Removed Natpro profile: $ProfilePath"
		}
		else
		{
			$TimeStamp = Get-Date -UFormat "%m/%d/%y - %H:%M:%S"
			Add-Content -Path $LogPath -Value "$TimeStamp> Failed to remove Natpro profile: $ProfilePath"
		}
	}
}