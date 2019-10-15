function Replace-CorruptedFiles
{
	param
	(
		[array]$CorruptList,
		[string]$Source,
		[string]$Path,
		[switch]$WhatIf
	)
	
	$repaired = @()
	foreach ($f in $CorruptList)
	{
		$local = "$Path\$($f.ItemPath)"
		$remote = "$Source\$($f.ItemPath)"
		
		$file = New-Object -TypeName PSObject
		$file | Add-Member -MemberType NoteProperty -Name Name -Value $((ls $local -ErrorAction SilentlyContinue).Name)
		$file | Add-Member -MemberType NoteProperty -Name Path -Value $((ls $local -ErrorAction SilentlyContinue).Directory)
        
        # Verify original file corruption
		if (Get-FileCorruption -Path $local)
		{
			$file | Add-Member -MemberType NoteProperty -Name Corrupted -Value True
            
            # Verify that file exists in clean source
			if (Test-Path $remote -ErrorAction SilentlyContinue)
			{
				$file | Add-Member -MemberType NoteProperty -Name Source -Value $((ls $remote -ErrorAction SilentlyContinue).Directory)
				$file | Add-Member -MemberType NoteProperty -Name Owner -Value $((Get-Acl -Path $remote).Owner)
				$file | Add-Member -MemberType NoteProperty -Name LastModifiedUtc -Value $((Get-ChildItem -Path $remote).LastWriteTimeUtc)
			}
			else
			{
                $file | Add-Member -MemberType NoteProperty -Name Source -Value ''
				$file | Add-Member -MemberType NoteProperty -Name Owner -Value ''
				$file | Add-Member -MemberType NoteProperty -Name LastModifiedUtc -Value ''
				$file | Add-Member -MemberType NoteProperty -Name Result -Value "Not present in remote source"
				continue
            }
            
            # Attempt to copy from clean source
			try
			{
				if ($WhatIf)
				{
					Copy-Item -Path $remote -Destination $local -Force -WhatIf
				}
				else
				{
					Copy-Item -Path $remote -Destination $local -Force
				}
			}
			catch
			{
				$file | Add-Member -MemberType NoteProperty -Name Result -Value $($f.Exception.Message)
				continue
			}
			$file | Add-Member -MemberType NoteProperty -Name Result -Value Replaced
		}
		else
		{
			$file | Add-Member -MemberType NoteProperty -Name Corrupted -Value False
        }
        
        $repaired += $file
        Clear-Variable -Name file
	}
	
	return $repaired
}