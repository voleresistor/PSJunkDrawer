[CmdletBinding()]
Param(
    [switch]$ListAllAvailable,
    [switch]$ExcludePreview,
    [switch]$ExcludeOutofBand
)
$ProgressPreference = 'SilentlyContinue'
$URI = "https://aka.ms/WindowsUpdateHistory" # Windows 10 release history

Function Get-MyWindowsVersion {
        [CmdletBinding()]
        Param
        (
            $ComputerName = $env:COMPUTERNAME
        )

        $Table = New-Object System.Data.DataTable
        $Table.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build"))
        $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
        Try
        {
            $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
        }
        Catch
        {
            $Version = "N/A"
        }
        $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
        $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
        $OSVersion = $CurrentBuild + "." + $UBR
        $TempTable = New-Object System.Data.DataTable
        $TempTable.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build"))
        [void]$TempTable.Rows.Add($env:COMPUTERNAME,$ProductName,$Version,$OSVersion)

        Return $TempTable
}

Function Convert-ParsedArray {
    Param($Array)
    
    $ArrayList = New-Object System.Collections.ArrayList
    foreach ($item in $Array)
    {      
        [void]$ArrayList.Add([PSCustomObject]@{
            Update = $item.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;',' - ')
            KB = "KB" + $item.href.Split('/')[-1]
            InfoURL = "https://support.microsoft.com" + $item.href
            OSBuild = $item.outerHTML.Split('(OS ')[1].Split()[1] # Just for sorting
        })
    }
    Return $ArrayList
}

If ($PSVersionTable.PSVersion.Major -ge 6)
{
    $Response = Invoke-WebRequest -Uri $URI -ErrorAction Stop
}
else 
{
    $Response = Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Stop
}
    
If (!($Response.Links))
{ throw "Response was not parsed as HTML"}
$VersionDataRaw = $Response.Links | where {$_.outerHTML -match "supLeftNavLink" -and $_.outerHTML -match "KB"}
$CurrentWindowsVersion = Get-MyWindowsVersion -ErrorAction Stop

If ($ListAllAvailable)
{
    If ($ExcludePreview -and $ExcludeOutofBand)
    {
        $AllAvailable = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Preview" -and $_.outerHTML -notmatch "Out-of-band"}
    }
    ElseIf ($ExcludePreview)
    {
        $AllAvailable = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Preview"}
    }
    ElseIf ($ExcludeOutofBand)
    {
        $AllAvailable = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Out-of-band"}
    }
    Else
    {
        $AllAvailable = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0]}
    }
    $UniqueList = (Convert-ParsedArray -Array $AllAvailable) | Sort OSBuild -Descending -Unique
    $Table = New-Object System.Data.DataTable
    [void]$Table.Columns.AddRange(@('Update','KB','InfoURL'))
    foreach ($Update in $UniqueList)
    {
        [void]$Table.Rows.Add(
            $Update.Update,
            $Update.KB,
            $Update.InfoURL
        )
    }
    Return $Table
}

$CurrentPatch = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'} | Select -First 1
If ($ExcludePreview -and $ExcludeOutofBand)
{
    $LatestAvailablePatch = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Out-of-band" -and $_.outerHTML -notmatch "Preview"} | Select -First 1
}
ElseIf ($ExcludePreview)
{
    $LatestAvailablePatch = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Preview"} | Select -First 1
}
ElseIf ($ExcludeOutofBand)
{
    $LatestAvailablePatch = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0] -and $_.outerHTML -notmatch "Out-of-band"} | Select -First 1
}
Else
{
    $LatestAvailablePatch = $VersionDataRaw | where {$_.outerHTML -match $CurrentWindowsVersion.'OS Build'.Split('.')[0]} | Select -First 1
}
    

$Table = New-Object System.Data.DataTable
[void]$Table.Columns.AddRange(@('OSVersion','OSEdition','OSBuild','CurrentInstalledUpdate','CurrentInstalledUpdateKB','CurrentInstalledUpdateInfoURL','LatestAvailableUpdate','LastestAvailableUpdateKB','LastestAvailableUpdateInfoURL'))
[void]$Table.Rows.Add(
    $CurrentWindowsVersion.Version,
    $CurrentWindowsVersion.'Windows Edition',
    $CurrentWindowsVersion.'OS Build',
    $CurrentPatch.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;',' - '),
    "KB" + $CurrentPatch.href.Split('/')[-1],
    "https://support.microsoft.com" + $CurrentPatch.href,
    $LatestAvailablePatch.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;',' - '),
    "KB" + $LatestAvailablePatch.href.Split('/')[-1],
    "https://support.microsoft.com" + $LatestAvailablePatch.href
    )
Return $Table