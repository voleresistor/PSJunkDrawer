<#
    Example of substitution to rename a file with several variables. This could be used to automatically
    name log files, or perform some regular rollover of log files.
#>
If (Test-Path $csvpath) {
    Rename-Item -Path $csvpath -NewName ("{0}.{1}.txt" -f $csvpath, (get-random).tostring())
}

function Test-TcpPort([string]$ComputerName, [int]$PortNumber)
{
    <#
    .SYNOPSIS
    Test to determine if a remote computer is listening on the specified port.
    
    .DESCRIPTION
    Attempt to create a TCP connection to the spcified port. If successful, return $true
    
    .PARAMETER ComputerName
    The name of the remote host to test.
    
    .PARAMETER PortNumber
    The port number on the remote host to test.
    
    .EXAMPLE
    Test-TcpPort -ComputerName Server01 -PortNumber 25
    #>
  try
  {
    $c = New-Object System.Net.Sockets.TcpClient($ComputerName, $PortNumber)
    $c.Close()
    return $true
  }
  catch
  {
    [system.exception]
    return $false
  }
}

function Set-HomedirPerms([string]$Path,[string]$Account,$Runs = 2)
{
    <#
    .SYNOPSIS
    Set permissions on home directories.
    
    .DESCRIPTION
    Use icacls.exe to reset inheritance and ownership of home directories in cases where settings may have drifted.
    
    .PARAMETER Path
    Homedir folder to correct.
    
    .PARAMETER Account
    User account to set as home directory owner.
    
    .PARAMETER Runs
    Number of times to loop through permissions to ensure that all files are captured. This defaults to 2 loops.
    
    .EXAMPLE
    Set-HomedirPerms -Path \\company.com\homedir\fred.user -Account COMPANY\fred.user

    #>
    $icaclArgs0 = $Path + " /q /c /t /inheritance:e"
    $icaclArgs1 = $Path + " /q /c /t /reset"
    $icaclArgs2 = $Path + " /q /c /t /setowner " + $Account

    $i = 1
    while ($i -lt $runs){
        $proc = Start-Process -FilePath $env:windir\System32\icacls.exe -ArgumentList $icaclArgs0 -NoNewWindow -PassThru -Wait
        $proc = Start-Process -FilePath $env:windir\System32\icacls.exe -ArgumentList $icaclArgs1 -NoNewWindow -PassThru -Wait
        $proc = Start-Process -FilePath $env:windir\System32\icacls.exe -ArgumentList $icaclArgs2 -NoNewWindow -PassThru -Wait
        $i++
    }
}

function Set-PrinterMode
{
    <#
    .SYNOPSIS
    Set print rendering modes on remote printers.
    
    .DESCRIPTION
    Set print rendering mode to server or client side on a list of remote printers. Printers must be installed on a print server.

    .PARAMETER ServerName
    Name of print server.

    .PARAMETER PrinterName
    Name of printer(s) to be modified.
    
    .PARAMETER RenderMode
    Client-side or server-side rendering. Possible entries: CSR, SSR
    
    .EXAMPLE
    Set-PrinterMode -ServerName Print01 -PrinterName "Accounting First Floor" -RenderMode CSR
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerName, # The name of the print server

        [Parameter(Mandatory=$true, Position=2)]
        [string]$PrinterName, # A single printer name

        [Parameter(Mandatory=$true, Position=3)]
        [Validateset('CSR', 'SSR')]
        [string]$RenderMode # CSR or SSR
    )

    Write-Host "Setting printers to $modeName...`r`n"

    foreach ($p in $PrinterName){
        Write-Host "$p... " -NoNewline
        Set-Printer -Name $p -ComputerName $ServerName -RenderingMode $RenderMode
        if (((Get-Printer -Name $p -ComputerName $ServerName -Full).RenderingMode) -eq "$RenderMode"){
            Write-Host "Done" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}

<#
TODO:
    This function currently relies on a reg key set by an installation script. It should
    query SCCM WMI to test for a pending reboot.
#>
function Get-SccmPendingReboot
{
    <#
    .SYNOPSIS
    Determine if SCCM is waiting for a pending reboot.
    
    .DESCRIPTION
    Check for SCCM registry key denoting reboot required by SCCM.
    
    .EXAMPLE
    Get-SccmPendingReboot
    
    .NOTES
    General notes
    #>

    if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\DXP' -Name 'RebootPending' -ErrorAction SilentlyContinue)
    {
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\DXP' -Name 'RebootPending' -Force
        return $true
    }
    else
    {
        return $false
    }
}

Function Start-CountDown
{
    <#
    .Synopsis
    Begins a visual countdown for use as a timer or alarm or simple task scheduler.
    
    .Description
    Takes wait time in seconds, minutes, hours or a completion time. Displays a countdown on screen with progress bar. Exits silently at end of countdown.
    
    .Parameter ActivityName
    Name of the activity being counted down.
    
    .Parameter WaitSeconds
    Number of seconds to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitMinutes
    Number of minutes to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitHours
    Number of hours to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitUntil
    Time in DateTime format to end countdown. This is exclusive with other $Wait<time> parameters.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitSeconds 15
    
    Begin a 15 second countdown.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitHours 2
    
    Begin a 2 hour countdown.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitUntil "11/19/2016"
    
    Begin a countdown until the specified date.
    #>
    
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ActivityName,
        
        [Parameter(Mandatory=$false)]
        [int]$WaitSeconds = 0,
        
        [Parameter(Mandatory=$false)]
        [int]$WaitMinutes = 0,
        
        [Parameter(Mandatory=$false)]
        [int]$WaitHours = 0,
        
        [Parameter(Mandatory=$false,ParameterSetName='WaitUntil')]
        [datetime]$WaitUntil
    )
    
    if ($WaitUntil)
    {
        $WaitSeconds = (New-TimeSpan -Start (Get-Date) -End $WaitUntil).TotalSeconds
    }
    else
    {
        $WaitSeconds = $WaitSeconds + ($WaitMinutes * 60) + ($WaitHours * 3600)
    }
    
    for ($t = 0; $t -lt $WaitSeconds; $t++)
    {
        $CurrentSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddSeconds($WaitSeconds - $t)
        $PercentComplete = ($t / $WaitSeconds) * 100
        
        $Hours = "{0:D2}" -f $($CurrentSpan.Hours)
        $Minutes = "{0:D2}" -f $($CurrentSpan.Minutes)
        $Seconds = "{0:D2}" -f $($CurrentSpan.Seconds)
        
        if ($CurrentSpan.Days -ne 0)
        {
            $Days = "{0:D2}" -f $($CurrentSpan.Days)
            $TimeLeft = "$Days`:$Hours`:$Minutes`:$Seconds"
        }
        else
        {
            $TimeLeft = "$Hours`:$Minutes`:$Seconds"
        }
        
        Write-Progress -Activity $ActivityName -Status $TimeLeft -PercentComplete $PercentComplete
        start-sleep -Seconds 1
        
        Clear-Variable CurrentSpan,PercentComplete,Hours,Minutes,Seconds,TimeLeft
    }
}

Function Get-PendingReboot
{
	<#
	.SYNOPSIS
	    Gets the pending reboot status on a local or remote computer.

	.DESCRIPTION
	    This function will query the registry on a local or remote computer and determine if the
	    system is pending a reboot, from either Microsoft Patching or a Software Installation.
	    For Windows 2008+ the function will query the CBS registry key as another factor in determining
	    pending reboot state.  "PendingFileRenameOperations" and "Auto Update\RebootRequired" are observed
	    as being consistant across Windows Server 2003 & 2008.

	    CBServicing = Component Based Servicing (Windows 2008)
	    WindowsUpdate = Windows Update / Auto Update (Windows 2003 / 2008)
	    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
	    PendFileRename = PendingFileRenameOperations (Windows 2003 / 2008)

	.PARAMETER ComputerName
	    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

	.PARAMETER ErrorLog
	    A single path to send error data to a log file.

	.EXAMPLE
	    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize

	    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
	    -------- ----------- ------------- ------------ -------------- -------------- -------------
	    DC01           False         False                       False                        False
	    DC02           False         False                       False                        False
	    FS01           False         False                       False                        False

	    This example will capture the contents of C:\ServerList.txt and query the pending reboot
	    information from the systems contained in the file and display the output in a table. The
	    null values are by design, since these systems do not have the SCCM 2012 client installed,
	    nor was the PendingFileRenameOperations value populated.

	.EXAMPLE
	    PS C:\> Get-PendingReboot

	    Computer       : WKS01
	    CBServicing    : False
	    WindowsUpdate  : True
	    CCMClient      : False
	    PendFileRename : False
	    PendFileRenVal : 
	    RebootPending  : True

	    This example will query the local machine for pending reboot information.

	.EXAMPLE
	    PS C:\> $Servers = Get-Content C:\Servers.txt
	    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation

	    This example will create a report that contains pending reboot information.

	.LINK
	    Component-Based Servicing:
	    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx

	    PendingFileRename/Auto Update:
	    http://support.microsoft.com/kb/2723674
	    http://technet.microsoft.com/en-us/library/cc960241.aspx
	    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

	    SCCM 2012/CCM_ClientSDK:
	    http://msdn.microsoft.com/en-us/library/jj902723.aspx

	.NOTES
	    Author:  Brian Wilhite
	    Email:   bwilhite1@carolina.rr.com
	    Date:    08/29/2012
	    PSVer:   2.0/3.0
	    Updated: 05/30/2013
	    UpdNote: Added CCMClient property - Used with SCCM 2012 Clients only
	             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
	             Removed $Data variable from the PSObject - it is not needed
	             Bug with the way CCMClientSDK returned null value if it was false
	             Removed unneeded variables
	             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","Computer")]
		[String[]]$ComputerName="$env:COMPUTERNAME",

		[String]$ErrorLog
	)

	Begin
	{
		# Adjusting ErrorActionPreference to stop on all errors, since using [Microsoft.Win32.RegistryKey]
		# does not have a native ErrorAction Parameter, this may need to be changed if used within another
		# function.
		$TempErrAct = $ErrorActionPreference
		$ErrorActionPreference = "Stop"
	}
	Process
	{
		Foreach ($Computer in $ComputerName)
		{
			Try
			{
				# Setting pending values to false to cut down on the number of else statements
				$PendFileRename,$Pending,$SCCM = $false,$false,$false
			
				# Setting CBSRebootPend to null since not all versions of Windows has this value
				$CBSRebootPend = $null

				# Querying WMI for build version
				$WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer

				# Making registry connection to the local/remote computer
				$RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$Computer)

				# If Vista/2008 & Above query the CBS Reg Key
				If ($WMI_OS.BuildNumber -ge 6001)
				{
					$RegSubKeysCBS = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames()
					$CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"

				}

				# Query WUAU from the registry
				$RegWUAU = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
				$RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
				$WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
				
				# Query PendingFileRenameOperations from the registry
				$RegSubKeySM = $RegCon.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
				$RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)
				
				# Closing registry connection
				$RegCon.Close()
				
				# If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
				If ($RegValuePFRO)
				{
					$PendFileRename = $true
				}

				# Determine SCCM 2012 Client Reboot Pending Status
				# To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
				$CCMClientSDK = $null
				$CCMSplat = @{
					NameSpace='ROOT\ccm\ClientSDK'
					Class='CCM_ClientUtilities'
					Name='DetermineIfRebootPending'
					ComputerName=$Computer
					ErrorAction='SilentlyContinue'
					}
				$CCMClientSDK = Invoke-WmiMethod @CCMSplat
				If ($CCMClientSDK)
				{
					If ($CCMClientSDK.ReturnValue -ne 0)
					{
						Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
					}

					If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
					{
						$SCCM = $true
					}

				}
				Else
				{
					$SCCM = $null
				}                        
				
				# If any of the variables are true, set $Pending variable to $true
				If ($CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
				{
					$Pending = $true
				}

				# Creating Custom PSObject and Select-Object Splat
				$SelectSplat = @{
					Property=('Computer','CBServicing','WindowsUpdate','CCMClientSDK','PendFileRename','PendFileRenVal','RebootPending')
					}
				New-Object -TypeName PSObject -Property @{
						Computer=$WMI_OS.CSName
						CBServicing=$CBSRebootPend
						WindowsUpdate=$WUAURebootReq
						CCMClientSDK=$SCCM
						PendFileRename=$PendFileRename
						PendFileRenVal=$RegValuePFRO
						RebootPending=$Pending
						} | Select-Object @SelectSplat
			}
			Catch
			{
				Write-Warning "$Computer`: $_"

				# If $ErrorLog, log the file to a user specified location/path
				If ($ErrorLog)
				{
					Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
				}

			}

		}

	}
	End
	{
		# Resetting ErrorActionPref
		$ErrorActionPreference = $TempErrAct
	}

}