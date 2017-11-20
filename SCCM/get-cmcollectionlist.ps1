param
(
    [string]$CollectionName,
    [string]$ServerName = 'housccm03.dxpe.com',
    [string]$ModulePath = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin",
    [string]$SiteCode = 'HOU',
    [string]$OutFileName
)

$oldPath = Get-Location
Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

if (!(Get-Module -Name 'ConfigurationManager'))
{
    exit 1
}

try
{
    Set-Location -Path "$SiteCode`:\"
    
    $collectionMembers = Get-CMCollectionMember -CollectionName $CollectionName
    $memberCount = $collectionMembers.Count
    
    foreach ($m in $collectionMembers)
    {
        Add-Content -Value $m.Name -Path "c:\temp\$OutFileName.txt"
    }
    
    return $memberCount
}
finally
{
   Set-Location $oldPath
   Remove-Module -Name 'ConfigurationManager'
}