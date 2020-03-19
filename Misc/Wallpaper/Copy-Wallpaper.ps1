# Wallpaper paths
$wpPath = @(
	'C:\Windows\Web\4K\Wallpaper\Windows',
	'C:\Windows\Web\Wallpaper\Windows'
)

# Replace original wallpapers
foreach ($path in $wpPath) {
	foreach ($img in Get-ChildItem -Path $path) {
		Rename-Item -Path $($img.FullName) -NewName "$($img.Directory)\$($img.BaseName)-Original$($img.Extension)"
		Copy-Item $PSScriptRoot\CorporateWallpaper.jpg $($img.FullName)
	}
}