New-PSDrive -PSProvider FileSystem -Name "depts" -Root "\\dxpe.com\data\departments"

$depts = (Get-ChildItem depts:\Marketing -Attributes Directory | Get-Acl)

foreach ($x in $depts){
    if ($depts.Access.IdentityReference.Value -match "NT AUTHORITY\Authenticated Users"){
        Write-Host $x.Path
    }
}

Remove-PSDrive -Name "depts" -Force