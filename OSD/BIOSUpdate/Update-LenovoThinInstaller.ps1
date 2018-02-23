param
(
    [string]$ThinRepo = "\\dxpepc2233\LenovoDriver",
    [string]$ThinArgs = "/CM -search A -action Install -Repository $ThinRepo -noicon -includerebootpackages 1,3,4",
    [string]$UpdaterExe = "Winuptp"
)

$ThinPathx86 = "$env:SystemDrive\Program Files\ThinInstaller"
$ThinPathx64 = "$env:SystemDrive\Program Files (x86)\ThinInstaller"
$ThinExe = "ThinInstaller.exe"

# Locate ThinInstaller
if (Test-Path -Path $ThinPathx64)
{
    $ThinPath = "$ThinPathx64\$ThinExe"
    Write-Host "$ThinPath found."
}
elseif (Test-Path -Path $ThinPathx86)
{
    $ThinPath = "$ThinPathx86\$ThinExe"
    Write-Host "$ThinPath found."
}
else
{
    Write-Host "ThinInstaller not found. Is it installed?"
    exit 1
}

# Verify we can see the repo
if (!(Test-Path -Path $ThinRepo))
{
    Write-Host "$ThinRepo not accessible."
    exit 1
}
else
{
    Write-Host "$ThinRepo is online and readable."
}

# Start update procedure
Write-Host "Starting updater: $ThinPath $ThinArgs"
Start-Process -FilePath $ThinPath -ArgumentList $ThinArgs -NoNewWindow

# Click "Yes" in the reboot confirmation window
$ThinWin = "Thin Installer"
$ws = New-Object -ComObject wscript.shell

$AppAct = $false
do
{
    $AppAct = $ws.AppActivate($ThinWin)
}
while ($AppAct -eq $false)
$ws.SendKeys('~')



# Start BIOS Flash
for ($i = 0; $i -lt 3; $i++)
{
    # Find Updater Window
    $BiosFlasher = $null
    do
    {
        Start-Sleep -Seconds 1
        $BiosFlasher = (Get-Process -Name $UpdaterExe -ErrorAction SilentlyContinue).MainWindowTitle
    }
    while ($BiosFlasher -eq $null)

    # Press enter on windows
    if ($ws.AppActivate($BiosFlasher))
    {
        Write-Host "Found $BiosFlasher. Starting Update."
    }
    $ws.SendKeys('~')
}
