function Filter-EventLogs
{
    param
    (
        [string]$ComputerName,
        [string]$LogName,
        [int]$LogID,
        [int]$Newest
    )

    # Gather messages
    if ($Newest)
    {
        $Messages = Get-EventLog -LogName $LogName -ComputerName $ComputerName -InstanceId $LogId -Newest $Newest
    }
    else
    {
        $Messages = Get-EventLog -LogName $LogName -ComputerName $ComputerName -InstanceId $LogId
    }

    # Generate array of results
    $results = @()

    # Process messages
    foreach ($m in $Messages)
    {
        # ReplacementStrings parse method from: https://community.spiceworks.com/topic/598706-parsing-the-message-field-in-security-event-log-to-pull-the-username
        $obj = New-Object -TypeName psobject
        $obj | Add-Member -MemberType NoteProperty -Name Time -Value $($m.TimeGenerated)
        $obj | Add-Member -MemberType NoteProperty -Name AccessType -Value $($m | Select @{Name='AccessType';Expression={ $_.ReplacementStrings[10]}}).AccessType
        $obj | Add-Member -MemberType NoteProperty -Name FileName -Value $($m | Select @{Name='FileName';Expression={ $_.ReplacementStrings[6]}}).FileName
        $obj | Add-Member -MemberType NoteProperty -Name UserName -Value $($m | Select @{Name='UserName';Expression={ $_.ReplacementStrings[1]}}).UserName
        $obj | Add-Member -MemberType NoteProperty -Name UserDomain -Value $($m | Select @{Name='UserDomain';Expression={ $_.ReplacementStrings[2]}}).UserDomain
        $results += $obj

        # Clean up
        Clear-Variable -Name obj
    }

    return $results
}