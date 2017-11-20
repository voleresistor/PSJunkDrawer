param(
    [string]$HomeDirBase,
    [switch]$NotATest,
    [string]$UserList,
    [string]$Domain = "dxpe.corp",
    [string]$SearchBase = "OU=NatPro,OU=Contractors,OU=Departments,DC=dxpe,DC=corp",
    $Cred = (get-credential)
)

Import-Module ActiveDirectory

function New-HomeDir (
    [string]$newhd,
    [string]$oldhd,
    [string]$unchd,
    [string]$user
) {
    if ((Test-Path -Path $newhd -ErrorAction SilentlyContinue) -eq $true){
        Return 1000
    } elseif ((Test-Path -Path $unchd -ErrorAction SilentlyContinue) -eq $true){
        if ($NotATest){
            # Rename homedir if a similar one already exists
            Rename-Item -Path $unchd -NewName $newhd -Force
            if ((Test-Path -Path $newhd -ErrorAction SilentlyContinue) -eq $true){
                Return 10
            } else {
                Return 1001
            }
        } else {
            Return 99
        }
    } elseif (((Test-Path -Path $unchd -ErrorAction SilentlyContinue) -eq $false) -and ((Test-Path -Path $newhd -ErrorAction SilentlyContinue) -eq $false)){
        if ($NotATest){
            #Create new homedir if nothing exists
            New-Item -Path $newhd -Force -ItemType Directory -ErrorAction SilentlyContinue
            
            # Set user as owner of new homedir
            $homedirACL = Get-Acl -Path $newhd

            $owner = New-Object System.Security.Principal.NTAccount($domain, $user)
            #$inheritance = [System.Security.AccessControl.InheritanceFlags]::"ContainerInherit", "ObjectInherit"
            #$propagation = [System.Security.AccessControl.PropagationFlags]::None
            #$rights = [System.Security.AccessControl.FileSystemRights]::FullControl
            #$type = [System.Security.AccessControl.AccessControlType]::Allow
            #$newacl = New-Object System.Security.AccessControl.FileSystemAccessRule($owner, $rights, $inheritance, $type)

            $homedirACL.SetOwner($owner)
            #$homedirACL.AddAccessRule($newacl)
            Set-Acl -Path $newHomedir -AclObject $homedirACL
            if ((Test-Path -Path $newhd -ErrorAction SilentlyContinue) -eq $true){
                Return 11
            } else {
                Return 1001
            }
        } else {
            Return 99
        }
    }

    Return 98
}

function Set-AdHomeDir(
    [string]$sid,
    [string]$newhd
){
    if ($NotATest){
        Get-ADUser -Filter { SID -eq $sid } -Server $domain -properties "HomeDirectory" | Set-ADUser -HomeDirectory $newHomeDir -Server $domain -Credential $Cred

        if ((Get-ADUser -Filter { SID -eq $sid } -Server $domain -Properties "HomeDirectory") -eq $newhd){
            Return 1000
        }else {
            Return 1001
        }
    } else {
        Return 99
    }
}

function Print-Out (
    [int]$retvalue,
    [string]$newhd,
    [string]$username,
    [string]$oldhd
){
    switch ($retvalue){
        0 { Write-Host "Something went wrong!" -ForegroundColor Red; exit }
        10 { Write-Host "Renamed" -ForegroundColor Green }
        11 { Write-Host "Created" -ForegroundColor Green }
        98 { Write-Host "Something went wrong!" -ForegroundColor Red; exit }
        99 { Write-Host "TEST" -ForegroundColor Magenta }
        100 { Write-Host "`r`nUser Name: " -NoNewline; Write-Host "$username" -ForegroundColor Cyan }
        101 { Write-Host "Old Homedir: " -NoNewline; Write-Host "$oldhd" -ForegroundColor Yellow }
        102 { Write-Host "New Homedir: " -NoNewline; Write-Host "$newhd" -ForegroundColor Green }
        110 { Write-Host "Verifying user homedir... " -NoNewline }
        111 { Write-Host "Setting user homedir... " -NoNewline }
        1000 { Write-Host "Success" -ForegroundColor Green }
        1001 { Write-Host "Failed" -ForegroundColor Red }
    }
}

function main (){
    if (!$UserList){
        $users = Get-AdUser -SearchBase $SearchBase -Filter { ObjectClass -eq "User" } -Property "samaccountname", "homedirectory", "sid"
        $users = $users | Where-Object { $_.HomeDirectory -ne $null }
    } elseif ($UserList){
        $users = Get-Content -Path $UserList
    }
    
    foreach ($user in $users){
        if ($UserList){
            $user = Get-AdUser -Filter { Name -eq $user } -Property "samaccountname", "homedirectory", "sid"
        }
    
        $oldHomeDir = $($user.HomeDirectory)
        $newHomeDir = $HomeDirBase + $($user.SamAccountName)
        $uncHomeDir = $HomeDirBase + $($user.Name)
        
        Print-Out -retvalue 100 -username $($user.Name)
        Print-Out -retvalue 101 -oldhd $($user.HomeDirectory)
        Print-Out -retvalue 102 -newhd $newhomedir
    
        Print-Out -retvalue 110

        $retvalue = New-HomeDir -newhd $newHomeDir -oldhd $oldHomeDir -unchd $uncHomeDir -user $user.SamAccountName
        Print-Out -retvalue $retvalue
    
        Print-Out -retvalue 111
        $retvalue = (Set-AdHomeDir -sid $user.sid -newhd $newHomeDir)
        Print-Out -retvalue $retvalue
    
        Clear-Variable -Name oldHomeDir
        Clear-Variable -Name newHomeDir
        Clear-Variable -Name uncHomeDir
    }
}

main