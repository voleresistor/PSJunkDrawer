function Get-RogueData {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CsvFile,

        [Parameter(Mandatory=$false)]
        [string]$CsvOut
    )

    # Import CSV
    try {
        $arrCsvData = Import-Csv -Path $CsvFile
    }
    catch {
        Write-Error $_.Exception.Message
        return
    }

    # Array of new data
    $arrResults = @()

    # Process CSV
    foreach ($e in $arrCsvData) {
        $strHostName = $(Resolve-DnsName -Name $e.{IP Address} -ErrorAction SilentlyContinue).NameHost
        $boolOnline = $(Test-Connection -IPv4 $e.{IP Address} -Count 1 -Quiet)
        $e.{Hostname(s)} = $strHostName
        $e | Add-Member -MemberType NoteProperty -Name 'Online' -Value $boolOnline
        $arrResults += $e
    }

    # Create new CSV
    if ($CsvOut) {
        foreach ($e in $arrResults) {
            Export-Csv -InputObject $e -Path $CsvOut -Append -NoTypeInformation
        }
    }

    return $arrResults
}