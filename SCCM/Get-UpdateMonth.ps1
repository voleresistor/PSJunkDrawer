#Get PatchTuesday
function Get-PatchTuesday
{
    param
    (
        [int]$MonthDig,
        [int]$Year
    )
    
    $PatchTuesday = ((Get-Date -Month $MonthDig -Day 1 -Year $Year).AddDays(-1))
    $TuesdayCount = 0
    
    while ($TuesdayCount -ne 2)
    {
        $PatchTuesday = $PatchTuesday.AddDays(1)
        if ($($PatchTuesday.DayOfWeek) -eq 'Tuesday')
        {
            $TuesdayCount++
        }
    }
    
    return $PatchTuesday
}

# Get-UpdateMonth
function Get-UpdateMonth
{
    # Get year
    $Year = (Get-Date).Year
    
    # Get month name
    $MonthDigit = (Get-Date).Month
    switch ($MonthDigit)
    {
        1 {$MonthName = 'January'}
        2 {$MonthName = 'February'}
        3 {$MonthName = 'March'}
        4 {$MonthName = 'April'}
        5 {$MonthName = 'May'}
        6 {$MonthName = 'June'}
        7 {$MonthName = 'July'}
        8 {$MonthName = 'August'}
        9 {$MonthName = 'September'}
        10 {$MonthName = 'October'}
        11 {$MonthName = 'November'}
        12 {$MonthName = 'December'}
    }
    
    # Get patch Tuesday
    $PatchTuesday = Get-PatchTuesday -MonthDig $MonthDigit -Year $Year
    
    # Get all significant days in DXP patching cycle
    $PreDepSrvDay = $PatchTuesday.AddDays(1)
    $PreDepWksDay = $PatchTuesday.AddDays(2)
    $TierOneDay = $PatchTuesday.AddDays(4)
    $ProdStart = $PatchTuesday.AddDays(11)
    $ProdEnd = $PatchTuesday.AddDays(12)
}