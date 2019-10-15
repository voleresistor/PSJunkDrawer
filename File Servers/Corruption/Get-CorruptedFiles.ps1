function Get-CorruptedFiles
{
	param
	(
		[string]$Path,
		
		[string[]]$Exclude
	)
	
	$corrupted_files_found = @()
	foreach ($f in ls $path -Attributes H,!H)
	{
		if ($f.PsIsContainer -and !($Exclude.Contains($f.Name)))
		{
			$corrupted_files_found += Get-CorruptedFiles -Path $($f.FullName)
		}
		else
		{
			Write-Progress -Activity "Scanning for corrupted files..." -CurrentOperation $($f.FullName)
			if (Get-FileCorruption -Path $($f.FullName))
			{
				$corrupted_files_found += $f
			}
		}
	}
	return $corrupted_files_found
}