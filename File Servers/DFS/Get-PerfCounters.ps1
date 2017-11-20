param(
    [string]$ComputerName
)

# ================================
# Variables
# ================================

# ================================
# Functions
# ================================

Function Read-Counter($SampleInterval, $MaxSamples){
    $CounterData = Get-counter "\\$ComputerName\$Counter" -SampleInterval $SampleInterval -MaxSamples $MaxSamples -ErrorAction SilentlyContinue
    $StrippedCounterData = $CounterData.Readings -replace '.* :', '' # There is a long string before the actual data. We're stripping that out here
    [single]$StrippedCounterData = "{0:N2}" -f $StrippedCounterData
}