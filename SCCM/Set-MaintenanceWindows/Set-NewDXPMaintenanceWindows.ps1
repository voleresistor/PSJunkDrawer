function Set-NewDXPMaintenanceWindows
{
    param
    (
        [Parameter(Mandatory=$false)]
        [datetime]$Year = "01/01/$((Get-Date).Year)",

        [Parameter(Mandatory=$false)]
        [int]$NthDay = 2,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')]
        [string]$DayOfWeek = 'Tuesday',

        [Parameter(Mandatory=$false)]
        [string]$PatchFolder = '\\dxpe.com\data\Departments\IT\SysOps\System Center\Architecture\SCCM\Patching'
    )

    # Import ConfigMgr PSH Module
    Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
    $MWBaseName = "SUP-"
    
    # Get the CMSITE SiteCode
    $SiteCode = Get-PSDrive -PSProvider CMSITE
    Set-Location "$($SiteCode.Name):\"
    
    <# Configure params for finding patch days
    $FindNthDay=2
    $WeekDay='Tuesday'
    $Today=Get-Date #>
    
    # This array will hold our patch schedule objects
    $PatchDays = @()
    
    # Find patch days for the current year
    for ($i = 0; $i -lt 12; $i++){
        $ThisMonth = $Year.AddMonths($i) # Iterate through months
        $todayM=$ThisMonth.Month.ToString() # Create string value for month name
        $todayY=$ThisMonth.Year.ToString() # Create string value for year
        [datetime]$StrtMonth=$todayM+'/1/'+$todayY
    
        # Find second Tuesday of current month
        while ($StrtMonth.DayofWeek -ine $WeekDay ) { $StrtMonth=$StrtMonth.AddDays(1) }
    
        # Create variables for oatch day object
        $dateStr = $StrtMonth.AddDays(7*($FindNthDay-1))
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
    }

    # Generate CSV patch schedule
    if (!(Test-Path -Path "$PatchFolder\$($Year.Year)" -ErrorAction SilentlyContinue))
    {
        New-Item -Path $PatchFolder -Name $($Year.Year) -ItemType Directory
    }
    $PatchDays | Export-Csv -Path "$PatchFolder\$($Year.Year)\$($Year.Year)-MWSchedule.csv"

    # For testing
    #return $PatchDays
    
    # Parse patch days in array to create MWs
    foreach ($DateSet in $PatchDays){
        $MWName = $MWBaseName + $DateSet.PatchDay
        
        # Create Pre-Deployment MW
        Write-Host "Setting MW: '$($MWName)' on Pre-Deploy &gt; $($DateSet.PreDeployDate + $DateSet.MWStartTime) - $($DateSet.PreDeployDate + $DateSet.MWEndTime)"
        $StartTime = [DateTime]::Parse($($DateSet.PreDeployDate + $DateSet.MWStartTime)) 
        $EndTime = [DateTime]::Parse($($DateSet.PreDeployDate + $DateSet.MWEndTime)) 
        $Schedule = New-CMSchedule -NonRecurring -Start $StartTime -End $EndTime
        New-CMMaintenanceWindow -ApplyTo SoftwareUpdatesOnly -CollectionID 'HOU0019C' -Schedule $Schedule -Name $MWName | Out-Null
    
        # Create Tier 1 MW
        Write-Host "Setting MW: '$($MWName)' on Tier 1 &gt; $($DateSet.Tier1Date + $DateSet.MWStartTime) - $($DateSet.Tier1Date + $DateSet.MWEndTime)"
        $StartTime = [DateTime]::Parse($($DateSet.Tier1Date + $DateSet.MWStartTime)) 
        $EndTime = [DateTime]::Parse($($DateSet.Tier1Date + $DateSet.MWEndTime)) 
        $Schedule = New-CMSchedule -NonRecurring -Start $StartTime -End $EndTime
        New-CMMaintenanceWindow -ApplyTo SoftwareUpdatesOnly -CollectionID 'HOU001B3' -Schedule $Schedule -Name $MWName | Out-Null
    
        # Create Tier 2a MW
        Write-Host "Setting MW: '$($MWName)' on Tier 2a &gt; $($DateSet.Tier2aDate + $DateSet.MWStartTime) - $($DateSet.Tier2aDate + $DateSet.MWEndTime)"
        $StartTime = [DateTime]::Parse($($DateSet.Tier2aDate + $DateSet.MWStartTime)) 
        $EndTime = [DateTime]::Parse($($DateSet.Tier2aDate + $DateSet.MWEndTime)) 
        $Schedule = New-CMSchedule -NonRecurring -Start $StartTime -End $EndTime
        New-CMMaintenanceWindow -ApplyTo SoftwareUpdatesOnly -CollectionID 'HOU001BC' -Schedule $Schedule -Name $MWName | Out-Null
    
        # Create Tier 2b MW
        Write-Host "Setting MW: '$($MWName)' on Tier 2b &gt; $($DateSet.Tier2bDate + $DateSet.MWStartTime) - $($DateSet.Tier2bDate + $DateSet.MWEndTime)"
        $StartTime = [DateTime]::Parse($($DateSet.Tier2bDate + $DateSet.MWStartTime)) 
        $EndTime = [DateTime]::Parse($($DateSet.Tier2bDate + $DateSet.MWEndTime)) 
        $Schedule = New-CMSchedule -NonRecurring -Start $StartTime -End $EndTime
        New-CMMaintenanceWindow -ApplyTo SoftwareUpdatesOnly -CollectionID 'HOU001BD' -Schedule $Schedule -Name $MWName | Out-Null
    
        Write-Host ""
    }
}

    <#
    Create maintenance windows for server collections for the year.
    Based on scripts left by David Lassen that pull date information from text files. Expanded to automatically
    build date list for DXPE specific collections.
    
    Author: Andrew Ogden
    Email: aogden@dxpe.com
    Date: 01/11/16
    
    TODO:
        - Generalize patch collections. Possibly collect them as an array of names or IDs in a parameter
    
    CHANGES:
        - 01/11/16
            Replaced deprecated command -ApplyToSoftwareupdatesOnly with new form: -ApplyTo 'SoftwareUpdatesOnly'
        - 01/13/20
            Converted to function
            Converted relevant vars into parameters
            Added automatic printout of CSV with yearly patching schedule
    #>