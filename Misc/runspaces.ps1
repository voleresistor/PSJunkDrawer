$SearchRoots = @(
    'HKLM:\SOFTWARE\Classes\CLSID',
    'HKLM:\SOFTWARE\Classes\TypeLib',
    'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID',
    'HKLM:\SOFTWARE\Classes\WOW6432Node\TypeLib',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components',
    'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
)

$ScriptBlock = {
    param($path)
    . 'C:\temp\git\PSJunkDrawer\Registry\Start-RegistrySearch.ps1'
    (Start-RegistrySearch -SearchRoot $path -SearchString 'cyberark').Name
}

$MaxThreads = (Get-CimInstance win32_processor).ThreadCount / 2
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$Jobs = @()

foreach ($r in $SearchRoots) {
    $PowerShell = [powershell]::Create()
    $PowerShell.RunspacePool = $RunspacePool
    $PowerShell.AddScript($ScriptBlock).AddArgument($r)
    $Jobs += New-Object -TypeName PSObject -Property @{
        Runspace = $PowerShell.BeginInvoke()
        PowerShell = $PowerShell
    }
}

while ($Jobs.Runspace.IsCompleted -contains $false) {
    Write-Progress -Activity "Search registry" -Status "$(($Jobs | ?{$_.Runspace.IsCompleted -eq $true}).Count)\$($SearchRoots.Count)"
    Start-Sleep -Seconds 1
}

foreach ($j in $Jobs) {
    $delKeys += $j.PowerShell.EndInvoke($j.Runspace)
    $j.PowerShell.Dispose()
}

return $delkeys

# Only with PS 7
# $SearchRoots | Foreach-Object -Parallel { 
#     . 'C:\temp\git\PSJunkDrawer\Registry\Start-RegistrySearch.ps1'
#     (Start-RegistrySearch -SearchRoot $_ -SearchString 'cyberark').Name
# }