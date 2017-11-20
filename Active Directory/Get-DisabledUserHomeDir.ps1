param
(
    [int]$LastLogonDays = 90,

    [ValidateSet('dxpe.com','dxpe.corp')]
    [string]$DomainName = 'dxpe.corp'
)

$oldUsers = @{}

try
{
    Write-Host "Getting disabled AD users..."
    $disabledUsers = Get-ADUser -Filter {Enabled -eq 'false'} -Properties HomeDirectory,LastLogonDate -Server $DomainName

    $temp = @()
    foreach ($u in $disabledUsers)
    {
        if ($u.Homedirectory -ne $null)
        {
            $temp += $u
        }

        $disabledUsers = $temp
    }

    $latestLogon = (Get-Date).AddDays(-90)
    $temp = @()
    foreach ($u in $disabledUsers)
    {
        if ($($u.LastLogonDate -as [DateTime]) -le $latestLogon)
        {
            $temp += $u
        }

        $disabledUsers = $temp
    }
}
catch
{
    Write-Warning -Message 'Unable to query disabled users!'
    exit 100
}

foreach ($user in $disabledUsers)
{
    Write-Progress -Activity 'Checking homedirs' -Status "Checking path: $($user.HomeDirectory)"

    if (Test-Path $($user.HomeDirectory))
    {
        $oldUsers.Add($($user.Name), $($user.HomeDirectory))
    }
}

return $oldUsers