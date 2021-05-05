function Copy-SharePermissions {
    param (
        [object]$ShareInfo,
        [string]$OldLetter,
        [string]$NewLetter
    )

    $full = $null
    $change = $null
    $read = $null

    $perm = Get-SmbShareAccess -Name $ShareInfo.Name

    foreach ($p in $perm) {
        if ($p.AccessRight -eq 'Full') {
            if ($full -ne $null) {
                $full += ",`"$($p.AccountName)`""
            }
            else {
                $full += "`"$($p.AccountName)`""
            }
        }

        if ($p.AccessRight -eq 'Change') {
            if ($change -ne $null) {
                $change += ",`"$($p.AccountName)`""
            }
            else {
                $change += "`"$($p.AccountName)`""
            }
        }

        if ($p.AccessRight -eq 'Read') {
            if ($read -ne $null) {
                $read += ",`"$($p.AccountName)`""
            }
            else {
                $read += "`"$($p.AccountName)`""
            }
        }
    }

    $newPath = $ShareInfo.Path -Replace ("${OldLetter}:", "${NewLetter}:")

    $smbParam = @{
        #Name = $($ShareInfo.Name)
        Name = "testShare"
        #Path = $($ShareInfo.Path -Replace ("${OldLetter}:", "${NewLetter}:"))
        Path = "C:\Temp"
        #Whatif = $true
    }
    
    if ($full) { $smbParam.FullAccess = "$($full)"}
    if ($change) { $smbParam.ChangeAccess = "$($change)"}
    if ($read) { $smbParam.ReadAccess = "$($read)"}

    #Write-Host "New-SmbShare -Name $($ShareInfo.Name) -FullAccess $full -ChangeAccess $change -ReadAccess $read -Path $newPath"

    Remove-SmbShare -Name $($ShareInfo.Name) -Confirm:$false -Whatif

    Write-Host $smbParam.FullAccess
    Write-Host $smbParam.ChangeAccess
    Write-Host $smbParam.ReadAccess

    New-SmbShare @smbParam
}