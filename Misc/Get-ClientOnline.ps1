function Get-ClientOnline {
	[cmdletbinding()]
	param (
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage="List of computers to monitor.",
            ValueFromPipelineByPropertyName=$true
        )]
		[string[]]$ComputerName,
		
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Time in seconds to wait between cycles."
        )]
		[int]$SleepSeconds = 60
	)
	
	[System.Collections.ArrayList]$Computers = $ComputerName
	
	while ($Computers.Count -ge 1) {
		$removeThese = @()
		foreach ($computer in $Computers) {
			if (Test-Connection -Count 1 -Quiet -TargetName $computer) {
				Write-Verbose "$Computer is online."
				Write-Host "$Computer is online." -ForegroundColor Green
				#New-NoticePopup -ComputerName $computer
				$removeThese += $computer
			}
			else {
				Write-Verbose "$Computer is offline."
			}
		}
		
		foreach ($computer in $removeThese) {
			while ($Computers -contains $computer) {
				$Computers.Remove($computer)
			}
		}
		Write-Verbose "Begin $SleepSeconds sleep..."
		Start-Sleep -Seconds $SleepSeconds
	}
}