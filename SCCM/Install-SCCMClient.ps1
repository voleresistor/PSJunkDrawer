<#
    Product: SCCM
    Purpose: Remotely push install SCCM Client on devices SCCM server can't connect to
    Version: 1.0 - 02/13/17

    Author: Andrew Ogden
    Email: andrew.ogden@dxpe.com
#>
function Install-SccmClient
{
    <#
    .SYNOPSIS
    Remotely push install SCCM Client on devices SCCM server can't connect to.
    
    .DESCRIPTION
    Remotely push install SCCM Client on devices SCCM server can't connect to.
    
    .PARAMETER ComputerName
    An array of computers to push the client to.
    
    .PARAMETER ClientLocation
    The path to the folder where ccmsetup.exe is stored.
    
    .PARAMETER InstallString
    A string of arguments to pass to ccmsetup.exe.
    
    .PARAMETER LogLocation
    The location to write the log file.
    
    .PARAMETER NoWait
    Don't wait for ccmsetup to finish installation before exiting. This is ignored for uninstallation.

    .PARAMETER Uninstall
    Uninstall existing SCCM client before installing the new one.
    
    .EXAMPLE
    Install-SccmClient -ComputerName pc001 -Clientlocation C:\temp -InstallString "/mp:cm01.contoso.com"

    Install the SCCM client on pc001 using the installer in c:\temp and set a management point of cm01.
    
    .NOTES
    General notes
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$ClientLocation,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$InstallString,

        [Parameter(Mandatory=$false, Position=4)]
        [string]$LogLocation = "C:\temp\Install-SCCMClient.log",

        [Parameter(Mandatory=$false, Position=5)]
        [switch]$NoWait,

        [Parameter(Mandatory=$false)]
        [switch]$Uninstall,

        [Parameter(DontShow)]
        [string]$ClientInstaller = 'ccmsetup.exe'
    )

    function Write-LogEntry
    {
        param
        (
            [string]$Value,
            [string]$LogFile = $LogLocation
        )
        $Time = Get-Date -UFormat '%D - %T'

        Add-Content -Value "[$Time]: $Value" -Path $LogFile
        Write-Host $Value
    }

    function Copy-Installer
    {
        param
        (
            [Parameter(Mandatory=$true, Position=1)]
            [string]$ComputerName,

            [Parameter(Mandatory=$true, Position=2)]
            [string]$ClientPath,

            [Parameter(Mandatory=$true, Position=3)]
            [string]$RemotePath,

            [Parameter(Mandatory=$true, Position=4)]
            [string]$LogFile
        )

        #Verify admin share connectivity
        Write-LogEntry -LogFile $LogFile -Value "Testing connectivity to the admin share on $ComputerName..."
        if (!(Test-Path -Path $RemotePath -ErrorAction SilentlyContinue))
        {
            Write-LogEntry -LogFile $LogFile -Value "Unable to connect to admin share on $ComputerName"
            return 1
        }
        Write-LogEntry -LogFile $LogFile -Value "Done"

        #Copy the installer
        try
        {
            Write-LogEntry -LogFile $LogFile -Value "Copying $ClientPath to $RemotePath"
            Copy-Item -Path $ClientPath -Destination $RemotePath -Force
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-LogEntry -LogFile $LogFile -Value "Error: Failed to copy installer"
            Write-LogEntry -LogFile $LogFile -Value "Error Message: $ErrorMessage"
            return 1
        }
        Write-LogEntry -LogFile $LogFile -Value "Done"
        return 0
    }

    function Install-Client
    {
        param
        (
            [Parameter(Mandatory=$true, Position=1)]
            [System.Management.Automation.Runspaces.PSSession]$RemoteSession,

            [Parameter(Mandatory=$true, Position=2)]
            [string]$ComputerName,

            [Parameter(Mandatory=$true, Position=3)]
            [string]$RemotePath,

            [Parameter(Mandatory=$true, Position=4)]
            [string]$ClientPath,

            [Parameter(Mandatory=$true, Position=5)]
            [string]$RemoteCommand,

            [Parameter(Mandatory=$true, Position=6)]
            [string]$LogFile
        )
        Write-LogEntry -LogFile $LogFile -Value "Install target: $ComputerName"

        #Run the installer
        try
        {
            Write-LogEntry -LogFile $LogFile -Value "Running command `"$RemoteCommand`" on $ComputerName"
            Invoke-Command -Session $RemoteSession -ScriptBlock {Invoke-Expression -Command  $($args[0])} -ArgumentList $RemoteCommand
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-LogEntry -LogFile $LogFile -Value "Error: Failed to start $(($ClientPath -split ('\\'))[-1]) on $ComputerName"
            Write-LogEntry -LogFile $LogFile -Value "Error Message: $ErrorMessage"
            return 1
        }
        Write-LogEntry -LogFile $LogFile -Value "Done"

        #Wait for ccmsetup to complete
        if (!($NoWait))
        {
            Write-LogEntry -LogFile $LogFile -Value "Waiting for $(($ClientPath -split ('\\'))[-1]) to exit..."
            $Begin = Get-Date
            $i = 0
            While (Get-Process -Name 'ccmsetup' -ComputerName $ComputerName -ErrorAction SilentlyContinue)
            {
                $Span = New-TimeSpan -Start $Begin -End (Get-Date)
                Write-Progress -Activity "Waiting for $(($ClientPath -split ('\\'))[-1]) to exit..." -Status "$($a[$i]) $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
                $i++
                if ($i -gt 3)
                {
                    $i = 0
                }

                #Mark progress
                if (($Span.TotalSeconds % 30) -eq 0)
                {
                    Write-LogEntry -LogFile $LogFile -Value "Mark: $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
                }
                Start-Sleep -Seconds 1
            }
            Write-LogEntry -LogFile $LogFile -Value "Done"
        }
        return 0
    }

    function Remove-Client
    {
        param
        (
            [Parameter(Mandatory=$true, Position=1)]
            [System.Management.Automation.Runspaces.PSSession]$RemoteSession,

            [Parameter(Mandatory=$true, Position=2)]
            [string]$ComputerName,

            [Parameter(Mandatory=$false, Position=3)]
            [string]$RemotePath,

            [Parameter(Mandatory=$true, Position=4)]
            [string]$ClientInstaller,

            [Parameter(Mandatory=$true, Position=6)]
            [string]$LogFile
        )
        Write-LogEntry -LogFile $LogFile -Value "Uninstall target: $ComputerName"
        
        #Run the installer
        try
        {
            $UninstallStr = "$RemotePath /uninstall"
            $RemoteCommand = "Start-Process -FilePath `"$RemotePath\$ClientInstaller`" -ArgumentList '/uninstall'"
            Write-LogEntry -LogFile $LogFile -Value "Running command `"$UninstallStr`" on $ComputerName"
            Invoke-Command -Session $RemoteSession -ScriptBlock {Invoke-Expression -Command  $($args[0])} -ArgumentList $RemoteCommand
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-LogEntry -LogFile $LogFile -Value "Error: Failed to start $UninstallStr on $ComputerName"
            Write-LogEntry -LogFile $LogFile -Value "Error Message: $ErrorMessage"
            return 1
        }
        Write-LogEntry -LogFile $LogFile -Value "Done"

        #Wait for ccmsetup to complete
        Write-LogEntry -LogFile $LogFile -Value "Waiting for $RemotePath to exit..."
        $Begin = Get-Date
        $i = 0
        While (Get-Process -Name 'ccmsetup' -ComputerName $ComputerName -ErrorAction SilentlyContinue)
        {
            $Span = New-TimeSpan -Start $Begin -End (Get-Date)
            Write-Progress -Activity "Waiting for `"$RemotePath\$ClientInstaller`" to exit..." -Status "$($a[$i]) $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
            $i++
            if ($i -gt 3)
            {
                $i = 0
            }

            #Mark progress
            if (($Span.TotalSeconds % 30) -eq 0)
            {
                Write-LogEntry -LogFile $LogFile -Value "Mark: $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
            }
            Start-Sleep -Seconds 1
        }
        Write-LogEntry -LogFile $LogFile -Value "Done"
        return 0
    }

    #Startup logging
    $a = @('-','\','|','/')
    Write-LogEntry -Value "*********************************************************************"
    Write-LogEntry -Value "Installing SCCM Client for the following computers:"
    foreach ($c in $ComputerName)
    {
        Write-LogEntry -Value "$c"
    }

    foreach ($c in $ComputerName)
    {
        #Attempt to connect using PSRemoting
        try
        {
            $RemoteDomain = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $c).Domain
            $RemotePath = "\\$c.$RemoteDomain\admin$\temp"
            $RemoteProgram = "$RemotePath\ccmsetup.exe"
            $RemoteCommand = "Start-Process -FilePath $RemoteProgram -ArgumentList '$InstallString'"

            Write-LogEntry -Value "Creating PS Session on $c.$RemoteDomain"
            $ClientSession = New-PSSession -ComputerName "$c.$RemoteDomain" -ErrorAction SilentlyContinue

            $Res = Copy-Installer -ComputerName "$c.$RemoteDomain" -ClientPath "$ClientLocation\$ClientInstaller" -RemotePath $RemotePath -LogFile $LogLocation
            if ($Res -ne 0)
            {
                continue
            }

            if ($Uninstall)
            {
                $Res = Remove-Client -RemoteSession $ClientSession -ComputerName "$c.$RemoteDomain" -RemotePath $RemotePath -LogFile $LogLocation -ClientInstaller $ClientInstaller
                if ($Res -ne 0)
                {
                    continue
                }
            }

            $Res = Install-Client -RemoteSession $ClientSession -ComputerName "$c.$RemoteDomain" -RemotePath $RemotePath -ClientPath "$ClientLocation\$ClientInstaller" -RemoteCommand $RemoteCommand -LogFile $LogLocation
            if ($Res -ne 0)
            {
                continue
            }
        }
        finally
        {
            Remove-PSSession -Session $ClientSession
        }
    }
}