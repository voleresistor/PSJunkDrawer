<#
    Product: SCCM
    Purpose: Remotely push install SCCM Client on devices SCCM server can't connect to
    Version: 1.0 - 02/13/17

    Author: Andrew Ogden
    Email: andrew.ogden@dxpe.com
#>

param
(
    [array]$ComputerName,
    [string]$RemoteFolder = 'ccmsetup',
    [string]$ClientLocation = '\\dxpe.com\sccm\Config Manager\Resources\SystemPackages\SCCM1606Client',
    [string]$ClientInstaller = 'ccmsetup.exe',
    [string]$InstallString = '/Source:C:\Windows\Temp\SccmClient SMSSITECODE=HOU /mp:housccm03.dxpe.com SMSCACHEFLAGS=PERCENTDISKSPACE;NTFSONLY SMSCACHESIZE=10 SMSMP=Housccm03.dxpe.com FSP=Housccm04.dxpe.com',
    [string]$LogLocation = "C:\temp\Install-SCCMClient.log",
    [switch]$NoWait
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

#Startup logging
$a = @('-','\','|','/')
Write-LogEntry -Value "*********************************************************************"
Write-LogEntry -Value "Installing SCCM Client for the following computers:"
foreach ($c in $ComputerName)
{
    Write-LogEntry -Value "$c"
}

#Main program loop
foreach ($c in $ComputerName)
{
    #Attempt to connect using PSRemoting
    try
    {
        Write-LogEntry -Value "Creating PS Session on $c"
        $ClientSession = New-PSSession -ComputerName $c -ErrorAction SilentlyContinue
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-LogEntry -Value "Error: Cannot connect to $c"
        Write-LogEntry -Value "Error Message: $ErrorMessage"
        continue
    }

    if ($ClientSession)
    {
        #Create variables
        $RemoteRoot = "\\$c\admin$"
        $RemotePath = "\\$c\admin$\$RemoteFolder"
        $RemoteProgram = "C:\Windows\$RemoteFolder\$ClientInstaller"
        $RemoteCommand = "Start-Process -FilePath $RemoteProgram -ArgumentList '$InstallString'"

        try
        {
            Write-LogEntry -Value "Install target: $c"
            
            #Verify admin share connectivity
            Write-LogEntry -Value "Testing connectivity to the admin share on $c..."
            if (!(Test-Path -Path $RemotePath -ErrorAction SilentlyContinue))
            {
                Write-LogEntry -Value "Unable to connect to admin share on $c"
                continue
            }
            Write-LogEntry -Value "Done"

            #Create the folder
            if (!(Test-Path -Path $RemotePath -ErrorAction SilentlyContinue))
            {
                try
                {
                    Write-LogEntry -Value "Creating remote path on $c"
                    New-Item -Path $RemoteRoot -Name $RemoteFolder -ItemType Directory -Force | Out-Null
                }
                catch
                {
                    $ErrorMessage = $_.Exception.Message
                    Write-LogEntry -Value "Error: Failed create remote folder on $c"
                    Write-LogEntry -Value "Error Message: $ErrorMessage"
                    continue
                }

                Write-LogEntry -Value "Done"
            }
            else
            {
                Write-LogEntry -Value "Remote folder already exists on $c"
            }

            #Copy the installer
            try
            {
                Write-LogEntry -Value "Copying $ClientInstaller to $c"
                Copy-Item -Path "$ClientLocation\$ClientInstaller" -Destination $RemotePath -Force
            }
            catch
            {
                $ErrorMessage = $_.Exception.Message
                Write-LogEntry -Value "Error: Failed copy installer to $c"
                Write-LogEntry -Value "Error Message: $ErrorMessage"
                continue
            }
            
            Write-LogEntry -Value "Done"

            #Run the installer
            try
            {
                Write-LogEntry -Value "Running command `"$RemoteCommand`" on $c"
                Invoke-Command -Session $ClientSession -ScriptBlock {param($RemoteCommand) Invoke-Expression $RemoteCommand} -ArgumentList $RemoteCommand
            }
            catch
            {
                $ErrorMessage = $_.Exception.Message
                Write-LogEntry -Value "Error: Failed to start $ClientInstaller on $c"
                Write-LogEntry -Value "Error Message: $ErrorMessage"
                continue
            }

            Write-LogEntry -Value "Done"

            #Wait for ccmsetup to complete
            if (!($NoWait))
            {
                Write-LogEntry -Value "Waiting for $ClientInstaller to exit..."
                $Begin = Get-Date
                $i = 0
                While (Get-Process -Name 'ccmsetup' -ComputerName $c -ErrorAction SilentlyContinue)
                {
                    $Span = New-TimeSpan -Start $Begin -End (Get-Date)
                    Write-Progress -Activity "Waiting for $ClientInstaller to exit..." -Status "$($a[$i]) $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
                    $i++
                    if ($i -gt 3)
                    {
                        $i = 0
                    }

                    #Mark progress
                    if (($Span.TotalSeconds % 30) -eq 0)
                    {
                        Write-LogEntry -Value "Mark: $("{0:D2}" -f $($Span.Minutes)):$("{0:D2}" -f $($Span.Seconds))"
                    }
                    Start-Sleep -Seconds 1
                }

                Write-LogEntry -Value "Done"
            }
        }
        finally
        {
            Write-LogEntry -Value "Removing PS Session for $c"
            Remove-PSSession $ClientSession
        }
    }
    else
    {
        Write-LogEntry -Value "Error: Cannot connect to $c"
        continue
    }
}