# Create a basic splat for params, then gather the data
$params = @{
    ReportType = 'Xml'
    Path = 'c:\windows\temp\cm-gpr.xml'
}
Get-GPResultantSetOfPolicy @params | Out-Null

# Read the XML and report back with the computer GPOs
[xml]$xmlResult = Get-Content -Path $($params.Path)
Write-Output $(($xmlResult.Rsop.UserResults.GPO | ?{$_.Enabled -eq $true} | Sort-Object Name).Name)