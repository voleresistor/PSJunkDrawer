$Policy_Array = @()
$dc01pols = Get-ChildItem -Path \\hdqdc01.dxpe.com\SYSVOL\dxpe.com\Policies
#$dc03pols = Get-ChildItem -Path \\houdc03.dxpe.com\SYSVOL\dxpe.com\Policies

foreach ($pol in $dc01pols){
    if ($($pol.Name) -eq "PolicyDefinitions"){
        continue
    }

    $polname = $pol.Name -replace '{','' -replace '}',''
    #$dc01_collection = @()
    #$dc03_collection = @()
    #
    #$dc01 = [pscustomobject]@{
    #    'Status' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).GpoStatus
    #    'PolicyDate' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).ModificationTime
    #    'ComputerDSVersion' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.DSVersion
    #    'ComputerSysvolVersion' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.SysvolVersion
    #    'UserDSVersion' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.DSVersion
    #    'UserSysvolVersion' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.SysvolVersion
    #}
    #
    #$dc03 = [pscustomobject]@{
    #    'Status' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).GpoStatus
    #    'PolicyDate' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).ModificationTime
    #    'ComputerDSVersion' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.DSVersion
    #    'ComputerSysvolVersion' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.SysvolVersion
    #    'UserDSVersion' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).User.DSVersion
    #    'UserSysvolVersion' = $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).User.SysvolVersion
    #}
    #
    ##$omwdc01 = [pscustomobject]@{
    ##    'Status' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).GpoStatus
    ##    'Policy Date' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).ModificationTime
    ##    'Computer DS Version' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.DSVersion
    ##    'Computer Sysvol Version' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.SysvolVersion
    ##    'User DS Version' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.DSVersion
    ##    'User Sysvol Version' = $(Get-GPO -Guid $polname -Server omwdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.SysvolVersion
    ##}
    #
    #$dc01_collection += Add-Member -InputObject $dc01 -TypeName My.GPOs -PassThru
    #$dc03_collection += Add-Member -InputObject $dc03 -TypeName My.GPOs -PassThru
    #
    #$polentry = [pscustomobject]@{
    #    'PolicyGUID' = $polname
    #    'PolicyName' = $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).DisplayName
    #    'HdqDC01' = $dc01_collection
    #    'HouDC03' = $dc03_collection
    #    #'OmwDC01' = $omwdc01
    #}

    $polentry = New-Object -TypeName psobject
    $polentry | Add-Member -MemberType NoteProperty -Name "PolicyGUID" -Value $polname
    $polentry | Add-Member -MemberType NoteProperty -Name "PolicyName" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).DisplayName
    
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01Status" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).GpoStatus
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01PolicyDate" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).ModificationTime
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01CompDSVer" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.DSVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01CompSysvolVer" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.SysvolVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01UserDSVer" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.DSVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC01UserSysvolVer" -Value $(Get-GPO -Guid $polname -Server hdqdc01 -Domain dxpe.com -ErrorAction SilentlyContinue).User.SysvolVersion
    
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03Status" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).GpoStatus
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03PolicyDate" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).ModificationTime
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03CompDSVer" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.DSVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03CompSysvolVer" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).Computer.SysvolVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03UserDSVer" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).User.DSVersion
    $polentry | Add-Member -MemberType NoteProperty -Name "DC03UserSysvolVer" -Value $(Get-GPO -Guid $polname -Server houdc03 -Domain dxpe.com -ErrorAction SilentlyContinue).User.SysvolVersion

    $Policy_Array += $polentry

    Clear-Variable polentry
    #Clear-Variable dc01
    #Clear-Variable dc03
    #Clear-Variable dc01_collection
    #Clear-Variable dc03_collection
    #Clear-Variable omwdc01
}

$Policy_Array