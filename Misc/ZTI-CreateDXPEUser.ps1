$Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"

# Local user account creation:
$TestUser = $Computer.Create("User", "DXPE")
$TestUser.SetPassword("TheFa11en")
$TestUser.SetInfo()
$TestUser.FullName = "DXP Enterprises"
$TestUser.SetInfo()
$TestUser.UserFlags = 0x10000
$TestUser.SetInfo()

$group = [ADSI]"WinNT://$Env:COMPUTERNAME/Users"  
$user = [ADSI]"WinNT://$Env:COMPUTERNAME/DXPE" 
$group.Add($user.Path)
