function Get-FileCorruption
{
	param
	(
		[string]$Path
	)
	
	# verify that local file is corrupt
	try
	{
		Get-FileHash -Path $Path -ErrorAction Stop | Out-Null
	}
	catch
	{
		return $true
	}
	
	return $false
}