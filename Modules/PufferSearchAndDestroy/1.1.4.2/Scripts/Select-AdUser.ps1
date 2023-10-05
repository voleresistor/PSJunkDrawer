function Select-AdUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, Position=1)]
		[string]$UserName
	)
	
	$arrUserName = $username -split(' ')
	$filter = ''
	for ($i = 0; $i -lt $arrUserName.Count; $i++) {
		if ($i -ne 0) {
			$filter += ' -or '
		}
		$filter += "(Name -like `"*$($arrUserName[$i])*`")"
	}
	
	return $(Get-AdUser -Filter $filter -Properties mail,employeeType | Out-GridView -Title "Select a user account" -PassThru)
}