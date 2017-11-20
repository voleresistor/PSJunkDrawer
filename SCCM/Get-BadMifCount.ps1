<#
    Get-BadMifCounts.ps1
    Harvest the PC name and number of times that PC has submitted a bad MIF file, as well as the latest bad MIF.
    Output as a CSV file.
#>

param
(
    [string]$MifBox = '\\housccm03.dxpe.com\SMS_HOU\inboxes\auth\dataldr.box\BADMIFS\ErrorCode_4',
    [string]$CsvOutFile = "c:\temp\$(Get-Date -uformat "%m%d")-badmifs.csv"
)

# Get the index of the array we're working with
function Get-MifIndex
{
    param
    (
        $GMI_Name
    )

    $x = 0
    foreach ($SubArray in $MifCounts)
    {
        if ($SubArray -contains $GMI_Name)
        {
            return $x
        }
        $x += 1
    }
    return -1
}

# Some constant?
$NameInd = 0
$CountInd = 1
$LatestInd = 2
$EarliestInd = 3

# Store data in an array of arrays before transferring it to file
$MifCounts = @()

foreach ($file in (Get-ChildItem -Path $MifBox -Filter *.mif))
{
    # Gather interesting data
    $ComputerName = ((Get-Content -Path $($file.FullName) | Select-String '//KeyAttribute') -split('<'))[2] -replace('>', '')
    $MifDate = $($file.LastWriteTime)
    $Index = Get-MifIndex -GMI_Name $ComputerName

    if ($Index -ge 0)
    {
        # Increment existing array
        $MifCounts[$Index][$CountInd] += 1

        # Update latest date if more recent than stored
        if ([datetime]$MifCounts[$Index][$LatestInd] -lt [datetime]$MifDate)
        {
            $MifCounts[$Index][$LatestInd] = $MifDate
        }

        # Update earliest date if less recent than stored
        if ([datetime]$MifCounts[$Index][$EarliestInd] -gt [datetime]$MifDate)
        {
            $MifCounts[$Index][$EarliestInd] = $MifDate
        }
    }
    else
    {
        # Create new array
        $tmp = @($ComputerName, 1, $MifDate, $MifDate)
        $MifCounts += , $tmp
    }

    Clear-Variable tmp,Index -ErrorAction SilentlyContinue
}

# Create the CSV
if (Test-Path -Path $CsvOutFile)
{
    Move-Item -Path $CsvOutFile -Destination "$CsvOutFile.old" -Force
}

Add-Content -Path $CsvOutFile -Value "ComputerName,BadMIFCount,Latest,Earliest"
foreach ($SubArray in $MifCounts)
{
    Add-Content -Path $CsvOutFile -Value "$($SubArray[0]),$($SubArray[1]),$($SubArray[2]),$($SubArray[3])"
}

<#
    Example output file:

    ComputerName,BadMIFCount,Latest,Earliest
    DXPEPC2363-A,2,09/29/2017 03:11:47,09/28/2017 04:30:10
    DXPELT1474,1,09/26/2017 05:45:57,09/26/2017 05:45:57
    DXPEPC2275,2,10/03/2017 04:07:05,09/30/2017 04:21:17
    DXPELT1213,1,09/29/2017 05:22:43,09/29/2017 05:22:43
#>