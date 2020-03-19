function Update-Wallpaper {
    <#
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$DesktopImage
    )

    $KeyPath = "HKCU:Control Panel\Desktop"

	# Only bother setting the desktop image if one was provided
	if ($DesktopImage) {
		if (!(Test-Path -Path $KeyPath -ErrorAction SilentlyContinue)) {
			New-Item -Path $KeyPath -Force
		}
	
		Set-Itemproperty -path $KeyPath -name WallPaper -value $DesktopImage
	}

    # Immediately refresh the desktop
    RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True
}

Update-Wallpaper -DesktopImage "$($env:systemroot)\XJTAssets\Wallpaper\CorporateWallpaper.jpg"