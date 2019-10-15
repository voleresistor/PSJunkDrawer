function Get-LogEntries
{
    param
    (
        [string]$LogName,
        [string]$EventID,
        [string]$SearchObject,
        [string]$AccountName
    )

    # Get log without unrolling all entries
    $log = Get-EventLog -List | Where-Object {$_.Log -ieq $LogName}
    if ($null -eq $log)
    {
        throw "Log not found: $LogName"
    }

    # Define a var to hold the last Index accessed
    $LastIndex = (Get-EventLog -LogName $LogName -Newest 1).Index

    # Loop until canceled by user
    while ($true)
    {
        # Get entries newer than LastIndex
        $entries = $log.Entries | Where-Object {($_.Index -gt $LastIndex) -and ($_.InstanceId -eq $EventId)}
        if ($entries -eq $null)
        {
            Write-Debug "No new entries."
        }
        else
        {
            # Update LastIndex
            $LastIndex = ($entries[-1]).Index

            # Pull useful data from the entries and write to stdout
            $details = Get-AccessDetails -InputObject $entries

            if ($SearchObject)
            {
                $filtered += $details | Where-Object {$_.ObjectName -match $SearchObject}
            }

            if ($AccountName)
            {
                $filtered += $details | Where-Object {$_.AccountName -match $AccountName}
            }

            if ($filtered)
            {
                $filtered | ft
                Clear-Variable filtered
            }
            else
            {
                $details | ft
                Clear-Variable details
            }

            # Clear vars so as not to pollute the next run
            Clear-Variable entries
        }

        # Wait a few seconds between cycles
        Start-Sleep -Seconds 1
    }
}