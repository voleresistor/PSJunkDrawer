function Get-JunkMailStatus {
	$allMailboxes = @()
	$mailboxes = Get-Mailbox -ResultSize Unlimited
	$mailboxes |
	% {
		$pct = ($mailboxes.IndexOf($_)) / ($mailboxes.Count) * 100
		Write-Progress -Activity 'Gather junkmail config' -CurrentOperation $_.PrimarySmtpAddress -PercentComplete $pct
		$results = @{
			'MailboxName' = $_.Name;
			'MailboxAlias' = $_.Alias;
			'MailboxGuid' = $_.Guid;
			'PrimarySmtpAddress' = $_.PrimarySmtpAddress
		}
		try {
			$junkmail = Get-MailboxJunkEmailConfiguration -Identity $_.Alias -ErrorAction Stop -WarningAction SilentlyContinue
			$results.Add('Status', $junkmail.Status)
			$results.Add('Enabled', $junkmail.Enabled)
			$results.Add('IsValid', $junkmail.IsValid)
		}
		catch {
			$results.Add('Status', 'ERROR')
			$results.Add('Enabled', 'ERROR')
			$results.Add('IsValid', 'ERROR')
		}
		$new_obj = New-Object -TypeName psobject -Property $results
		$allMailboxes += $new_obj
	}
	return $allMailboxes
}
