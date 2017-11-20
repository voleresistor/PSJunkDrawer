<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.116
	 Created on:   	2/18/2016 09:42
	 Created by:   	Colin Squier <hexalon@gmail.com>
	 Filename:     	Enable-BitLocker.ps1
	===========================================================================
	.DESCRIPTION
		Automates configuration of BitLocker drive encryption.
#>

[CmdletBinding()]
Param ()

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
	Break
}

$RequiredOSVersion = "10.0.10240" #RTM version of Windows 10
$Option = New-CimSessionOption -Protocol Dcom
$Session = New-CimSession -SessionOption $Option -ComputerName $env:COMPUTERNAME

$OS = (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $Session)

if (([version]$OS.Version -ge $RequiredOSVersion) -and ($OS.ProductType -eq 1))
{
	#Prepare drive for BitLocker
	$Tpm = (Get-Tpm)
	
	if (($Tpm.TpmPresent) -and ($Tpm.TpmReady))
	{
		$Volume = (Get-WmiObject -Class Win32_EncryptableVolume -Namespace "root\CIMv2\Security\MicrosoftVolumeEncryption" | Where-Object { $_.DriveLetter -eq $Env:SystemDrive })
		
		if ($volume.DriveLetter -eq $ENV:SystemDrive)
		{
			Write-Verbose "$env:SystemDrive is ready for encryption."
		}
		else
		{
			Write-Verbose "$env:SystemDrive is not ready for encryption. Preparing $env:SystemDrive for encryption. Computer will be restarted automatically after preperation."
			$PrepareDriveInfo = New-Object System.Diagnostics.ProcessStartInfo
			$PrepareDriveInfo.FileName = "bdehdcfg.exe"
			$PrepareDriveInfo.RedirectStandardError = $true
			$PrepareDriveInfo.RedirectStandardOutput = $true
			$PrepareDriveInfo.UseShellExecute = $false
			$PrepareDriveInfo.Arguments = "-target default"
			$PrepareDriveProcess = New-Object System.Diagnostics.Process
			$PrepareDriveProcess.StartInfo = $PrepareDriveInfo
			$PrepareDriveProcess.Start() | Out-Null
			$PrepareDriveProcess.WaitForExit()
			$StdOut = $PrepareDriveProcess.StandardOutput.ReadToEnd()
			$StdErr = $PrepareDriveProcess.StandardError.ReadToEnd()
			$ExitCode = $PrepareDriveProcess.ExitCode
			
			Write-Verbose -Message $StdOut
			
			if ($ExitCode -ne 0)
			{
				Write-Verbose "An error has occured."
				Write-Error -Message "Error: $StdErr"
			}
			Restart-Computer -Force
		}
		
		$BitlockerStatus = (Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus
		if (!( Test-Path "\\dxpe.com\sccm\MDT\OS Deployment\Logs\Keys\$env:COMPUTERNAME"))
		{
			New-Item -Path "\\dxpe.com\sccm\MDT\OS Deployment\Logs\Keys\$env:COMPUTERNAME" -ItemType Directory
		}
		$RecoveryKeyPath = "\\dxpe.com\sccm\MDT\OS Deployment\Logs\Keys\$env:COMPUTERNAME"
		$RecoveryKeyFilePath = "Z:"
		
		if ($BitlockerStatus -eq "On")
		{
			Write-Verbose "BitLocker already enabled on $env:SystemDrive"
			#Save recovery key to text file
			$BitLocker = ((Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' })
			if ($BitLocker.KeyProtectorType -eq "RecoveryPassword")
			{
				Write-Verbose "Saving BitLocker recovery key to a text file in $RecoveryKeyPath"
				$BitLockerId = $Bitlocker.KeyProtectorId
				$BitlockerId = ($BitLockerId -replace '[{}]', '')
				$RecoveryKeyFileName = "BitLocker Recovery Key " + $BitLockerId + " " + $env:COMPUTERNAME + ".txt"
				$RecoveryKeyDrive = (Get-PSDrive -PSProvider FileSystem)
				if (($RecoveryKeyDrive | Where-Object { $_.Name -eq "Z" }).Name -ne "Z")
				{
					New-PSDrive -Name "Z" -PSProvider FileSystem -Root $RecoveryKeyPath
				}
				
				$RecoveryKey = $BitLocker.RecoveryPassword
				$RecoveryFileContent = @"
BitLocker Drive Encryption recovery key

To verify that this is the correct recovery key, compare the start of the following identifier with the identifier value displayed on your PC.

Identifier:

	$BitLockerId

If the above identifier matches the one displayed by your PC, then use the following key to unlock your drive.

Recovery Key:

    $RecoveryKey

If the above identifier doesn't match the one displayed by your PC, then this isn't the right key to unlock your drive.
Try another recovery key, or refer to http://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.
"@
				$RecoveryKeyFileName = (Join-Path Z: -ChildPath $RecoveryKeyFileName)
				$RecoveryFileContent | Out-File $RecoveryKeyFileName -Encoding UTF8
				(Get-Content $RecoveryKeyFileName | Out-String) -replace "`n", "`r`n" | Out-File $RecoveryKeyFileName -Encoding UTF8
				if (($RecoveryKeyDrive | Where-Object { $_.Name -eq "Z" }).Name -eq "Z")
				{
					Remove-PSDrive -Name "Z"
				}
			}
		}
		else
		{
			Write-Verbose "Enabling BitLocker encryption on $env:SystemDrive, this will take some time."
			$RecoveryKeyDrive = (Get-PSDrive -PSProvider FileSystem)
			if (($RecoveryKeyDrive | Where-Object { $_.Name -eq "Z" }).Name -ne "Z")
			{
				New-PSDrive -Name "Z" -PSProvider FileSystem -Root $RecoveryKeyPath
			}
			
			Enable-BitLocker -EncryptionMethod Aes128 -RecoveryPasswordProtector -MountPoint $env:SystemDrive -SkipHardwareTest
			
			do
			{
				$Volume = (Get-BitLockerVolume -MountPoint $env:SystemDrive)
				Write-Progress -Activity "Encrypting volume $($Volume.MountPoint)" -Status "Encryption Progress:" -PercentComplete $Volume.EncryptionPercentage
				Start-Sleep -Seconds 1
			}
			until ($Volume.VolumeStatus -eq 'FullyEncrypted')
			
			Write-Progress -Activity "Encrypting volume $($Volume.MountPoint)" -Status "Encryption Progress:" -Completed
			
			$BitLocker = ((Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' })
			$BitLockerId = $Bitlocker.KeyProtectorId
			$BitlockerId = ($BitLockerId -replace '[{}]', '')
			$RecoveryKeyFileName = "BitLocker Recovery Key " + $BitLockerId + ".txt"
			$File = (Join-Path $RecoveryKeyFilePath -ChildPath $RecoveryKeyFileName)
			
			if (Test-Path $File)
			{
				$RecoveryKeyFileName = "Bitlocker Recovery Key " + $BitLockerId + " " + $env:COMPUTERNAME + ".txt"
				Rename-Item -Path $File -NewName $RecoveryKeyFileName
				[System.IO.FileInfo]$RecoveryKeyFile = (Get-ChildItem -Path $RecoveryKeyFilePath -Name $RecoveryKeyFileName)
			}
			else
			{
				$BitLocker = ((Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' })
				if ($BitLocker.KeyProtectorType -eq "RecoveryPassword")
				{
					Write-Verbose "Saving BitLocker recovery key to a text file in $RecoveryKeyPath"
					$BitLockerId = $Bitlocker.KeyProtectorId
					$BitlockerId = ($BitLockerId -replace '[{}]', '')
					$RecoveryKeyFileName = "BitLocker Recovery Key " + $BitLockerId + " " + $env:COMPUTERNAME + ".txt"
					$RecoveryKeyDrive = (Get-PSDrive -PSProvider FileSystem)
					if (($RecoveryKeyDrive | Where-Object { $_.Name -eq "Z" }).Name -ne "Z")
					{
						New-PSDrive -Name "Z" -PSProvider FileSystem -Root $RecoveryKeyPath
					}
					
					$RecoveryKey = $BitLocker.RecoveryPassword
					$RecoveryFileContent = @"
BitLocker Drive Encryption recovery key

To verify that this is the correct recovery key, compare the start of the following identifier with the identifier value displayed on your PC.

Identifier:

	$BitLockerId

If the above identifier matches the one displayed by your PC, then use the following key to unlock your drive.

Recovery Key:

	$RecoveryKey

If the above identifier doesn't match the one displayed by your PC, then this isn't the right key to unlock your drive.
Try another recovery key, or refer to http://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.
"@
					$RecoveryKeyFileName = (Join-Path Z: -ChildPath $RecoveryKeyFileName)
					$RecoveryFileContent | Out-File $RecoveryKeyFileName -Encoding UTF8
					(Get-Content $RecoveryKeyFileName | Out-String) -replace "`n", "`r`n" | Out-File $RecoveryKeyFileName -Encoding UTF8
				}
				
				$BitLocker = ((Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq 'Tpm' })
				if ($BitLocker.KeyProtectorType -ne "Tpm")
				{
					Get-BitLockerVolume -MountPoint $env:SystemDrive | Add-BitLockerKeyProtector -TpmProtector
				}
				
				if (($RecoveryKeyDrive | Where-Object { $_.Name -eq "Z" }).Name -eq "Z")
				{
					Remove-PSDrive -Name "Z"
				}
			}
		}
	}
	else
	{
		Write-Error -Message "The system does not meet system requirements, enable the TPM module in the BIOS." -Category ResourceUnavailable
	}
}
else
{
	Write-Error -Message "The Operating System does not meet system requirements." -Category ResourceUnavailable
}

Remove-CimSession -CimSession $Session