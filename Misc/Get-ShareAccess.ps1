param
(
    [string]$TargetPath = '\\dxpe.com\data\departments\Finance\Accounting\',
    [string]$CsvOut,
    [string]$Debug
)

$foldersec = Get-NTFSAccess -Path $TargetPath
$UsersAccess = @()

foreach ($perm in $foldersec)
{
    if ($perm.Account.AccountName -eq '')
    {
        if ($Debug)
        {
            Write-Host "Skipping orphaned SID $($perm.Account.Sid)"
        }
        continue
    }
    else
    {
        $domain = ($perm.Account.AccountName -split '\\')[0]
        $account = ($perm.Account.AccountName -split '\\')[1]
        $sid = ($perm.Account.Sid)
        
        if ($domain -eq 'BUILTIN')
        {
            if ($Debug)
            {
                Write-Host "Skipping BUILTING account $($perm.Account.AccountName)"
            }
            continue
        }
        elseif ($domain -eq 'DXPE')
        {
            $domainName = 'dxpe.corp'
            if ($Debug)
            {
                Write-Host "Domain is $domainName for $($perm.Account.AccountName)"
            }
        }
        elseif ($domain -eq 'DXPECOM')
        {
            $domainName = 'dxpe.com'
            if ($Debug)
            {
                Write-Host "Domain is $domainName for $($perm.Account.AccountName)"
            }
        }
        
        $accountInfo = Get-ADUser -Filter {SID -eq $sid} -Server $domainName
        $groupInfo = Get-ADGroup -Filter {Name -eq $account} -Server $domainName | Get-ADGroupMember -Server $domainName    -Recursive
    }
    
    if ($accountInfo)
    {
        $userObj = New-Object -TypeName psobject
        $userObj | Add-Member -MemberType NoteProperty -Name UserName -Value $accountInfo.Name
        $userObj | Add-Member -MemberType NoteProperty -Name AccessFrom -Value 'Direct'
        
        $UsersAccess += $userObj
        Clear-Variable -Name 'userObj'
    }
    elseif ($groupInfo)
    {
        foreach ($account in $groupInfo)
        {
            $userObj = New-Object -TypeName psobject
            $userObj | Add-Member -MemberType NoteProperty -Name UserName -Value $account.Name
            $userObj | Add-Member -MemberType NoteProperty -Name AccessFrom -Value $($perm).Account.AccountName
            
            $UsersAccess += $userObj
            Clear-Variable -Name 'userObj'
        }
    }

    Clear-Variable -Name 'accountInfo','groupInfo','domain','domainName','account','sid'
}
if ($CsvOut)
{
    Add-Content -Value "UserName,AccessFrom" -Path $CsvOut
    
    foreach ($user in $UsersAccess)
    {
        Add-Content -Value "$($user.UserName),$($user.AccessFrom)" -Path $CsvOut
    }
}
else
{
    return $UsersAccess
}