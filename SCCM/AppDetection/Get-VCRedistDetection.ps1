# Edit this array to detect for a particular version
# Copy key names from the PackagesFound hash table
# Script returns positive detection on the first item from this list to evaluate $True
$TargetVers = @(
    "2015-2019x64",
    "2015-2019x86"
)

$PackagesFound = @{
    "2005" = $False;
    "2008x86" = $False;
    "2010x86" = $False;
    "2012x86" = $False;
    "2013x86" = $False;
    "2015-2019x86" = $False;
    "2005x64" = $False;
    "2008x64" = $False;
    "2010x64" = $False;
    "2012x64" = $False;
    "2013x64" = $False;
    "2015-2019x64" = $False;
}

$UninstallKeys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
    $UninstallKeys += Get-ChildItem HKLM:\SOFTWARE\WoW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
}

$Year = ""
$Architecture = ""

$UninstallKeys | ForEach-Object { 
    $CurDisplayName = $_.GetValue("DisplayName")
    if( $CurDisplayName -match "^Microsoft Visual C\+\+\D*(?<Year>(\d|-){4,9}).*Redistributable.*") {
        $Year = $Matches.Year
        [Void] ($CurDisplayName -match "(?<Arch>(x86|x64))")
        $Architecture = $Matches.Arch
        $PackagesFound[ ''+$Year+$Architecture ] = $True
    }
}

foreach ($tv in $TargetVers) {
    if ($PackagesFound[$tv] -eq $true) {
        Write-Output "Desired version of Visual C++ found!"
        $PackagesFound
        return
    }
}
