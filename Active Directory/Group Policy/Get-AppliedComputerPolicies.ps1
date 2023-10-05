#lol logging
Start-Transcript -Path "c:\windows\temp\get-appliedcomputerpolicies.log"

# Clean up old reports
$xmlOutPath = 'c:\windows\temp\cm-gpr.xml'
if (Test-Path -Path $xmlOutPath -ErrorAction SilentlyContinue) {
    Remove-Item -Path $xmlOutPath -Force
}

do {
    # Select any old random user to abuse
    $UserName = "PUFFER_S\$(((Get-CimInstance -ClassName win32_userprofile | ?{$_.SID -like 'S-1-5-21-*'} | Get-Random).LocalPath -Split('\\'))[-1])"

    # Create a basic splat for params, then gather the data
    $params = @{
        ReportType = 'Xml'
        Path = $xmlOutPath
        Computer = $env:ComputerName
        User = $UserName
    }
    Get-GPResultantSetOfPolicy @params | Out-Null
} until (Test-Path $xmlOutPath -ErrorAction SilentlyContinue)

# Read the XML and report back with the computer GPOs
[xml]$xmlResult = Get-Content -Path $($params.Path)
Write-Output $(($xmlResult.Rsop.ComputerResults.GPO | ?{$_.Enabled -eq $true} | Sort-Object Name).Name)

# lol still logging
Stop-Transcript