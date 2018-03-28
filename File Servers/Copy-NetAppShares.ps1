param
(
    [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=1)]
    [string]$SourcePath,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$DestServer,

    [Parameter(Mandatory=$true, Position=3)]
    [string]$DestDrive,

    [Parameter(Mandatory=$true, Position=4)]
    [string]$ContainingFolder,

    [string]$InvokePath = '\\houdfs04.dxpe.com\homedir$\aogden\git\powershell\Misc\Invoke-RoboCopy.ps1',

    [string]$LogPath = 'C:\temp\robologs'
)

# include Invoke-RoboCopy
Write-Host "Loading Invoke-RoboCopy module... " -NoNewline
try
{
    . $InvokePath
    Write-Host "DONE" -ForegroundColor Green
}
catch
{
    Write-Host "FAILED" -ForegroundColor Red
    return -10
}

# Open a session on the target server
$ReSess = New-PSSession -ComputerName $DestServer

# Build some base variables
$SharePath = "${DestDrive}:\"
if ($ContainingFolder)
{
    $SharePath += $ContainingFolder
}

$DestPath = "\\$DestServer\$DestDrive$"
if ($ContainingFolder)
{
    $DestPath += "\$ContainingFolder"
}

foreach ($share in $SourcePath)
{
    # Get share name
    [string]$ShareName = $share.Split('\\')[-1]

    # Create folder on remote server if necessary
    Write-Host "$DestPath"
    if (Test-Path -Path $DestPath)
    {
        if (!(Test-Path -Path "$DestPath\$ShareName"))
        {
            Write-Host "Creating folder on remote server... " -NoNewline
            try
            {
                New-Item -Path $DestPath -Name $ShareName -ItemType Directory | Out-Null
                Write-Host "DONE" -ForegroundColor Green
            }
            catch
            {
                Write-Host "FAILED" -ForegroundColor Red
                return -20
            }
        }
    }
    else
    {
        Write-Host "Can't connect to destination" -ForegroundColor Yellow
        return -1
    }

    # Copy the files
    try
    {
        Write-Host "$LogPath\$ShareName.log... " -NoNewline
        Invoke-RoboCopy -Source $share -Destination "$DestPath\$ShareName" -Mirror -Recurse -Copy "DATSO" -DCopy "DAT" -LogLocation "$LogPath\$ShareName.log" | Out-Null
        Write-Host "DONE" -ForegroundColor Green
    }
    catch
    {
        Write-Host "An error ocurred" -ForegroundColor Yellow
    }

    # Create new share
    try
    {
        Write-Host "Creating new SMB share... " -NoNewline
        Invoke-Command -Session $ReSess -ScriptBlock { New-SmbShare -Path $($args[0]) -Name $($args[1]) -FullAccess 'Everyone' } -ArgumentList "$SharePath\$ShareName", $ShareName | Out-Null
        Write-Host "DONE" -ForegroundColor Green
    }
    catch
    {
        Write-Host "FAILED" -ForegroundColor Red
        return -30
    }
}
