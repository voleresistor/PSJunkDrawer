function Get-PatchDay
{
    param
    (
        [Parameter(Mandatory=$false)]
        [int]$FindNthDay = 2, # Defaults to 2 while Patch Tuesday schedule remains stable
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [string]$WeekDay ='Tuesday' # Defaults to Tuesday while Patch Tuesday schedule remains stable
    )

    # This array will hold our patch schedule objects
    $PatchDays = @()

    # Right now
    $Today=Get-Date

    # Find patch days for the current year
    $i = 1
    while ($i -le 12)
    {
        [datetime]$ThisMonth = "$i/01"  # Iterate through months

        # Find second Tuesday of current month
        while ($ThisMonth.DayofWeek -ine $WeekDay ) { $ThisMonth=$ThisMonth.AddDays(1) }

        # Create variables for oatch day object
        $dateStr = $ThisMonth.AddDays(7*($FindNthDay-1))
        $dateTier0 = (Get-Date ($dateStr.AddDays(2)) -UFormat "%m/%d/%Y")
        $dateTier1 = (Get-Date ($dateStr.AddDays(4)) -UFormat "%m/%d/%Y")
        $dateTier2a = (Get-Date ($dateStr.AddDays(11)) -UFormat "%m/%d/%Y")
        $dateTier2b = (Get-Date ($dateStr.AddDays(12)) -UFormat "%m/%d/%Y")
        $dateMD = (Get-Date ($dateStr) -UFormat "%B %d")
        $dateMDY = (Get-Date ($dateStr) -UFormat "%m/%d/%Y")

        # Create the patch day object. Add patch days for each collection DXP is using
        $PatchDayObj = New-Object -TypeName PSObject
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'PatchDay' -Value $dateMD
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'PatchReleaseDate' -Value $dateMDY
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'PreDeployDate' -Value $DateTier0
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'Tier1Date' -Value $DateTier1
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'Tier2aDate' -Value $DateTier2a
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'Tier2bDate' -Value $DateTier2b
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'MWStartTime' -Value " 1:00"
        $PatchDayObj | Add-Member -MemberType NoteProperty -Name 'MWEndTime' -Value " 5:00"

        # Add current month object to array
        $PatchDays += $PatchDayObj

        $i++
    }

    return $PatchDays
}