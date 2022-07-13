function Get-LogonEvents {
    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [datetime]$StartTime,

        [Parameter(Mandatory=$false,Position=2)]
        [datetime]$EndTime,

        [Parameter(Mandatory=$false,Position=3)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false,Position=4)]
        [switch]$Detail
    )

    # Interesting EventIDs
    # https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/basic-audit-logon-events
    # 4624
    # 4672

    # Even if the user doesn't give us an end time, we need one
    if (!($EndTime))
    {
        $EndTime = Get-Date
    }

    # Gather the events
    $FilterHash = @{LogName='Security'; ID=4624,4672; StartTime=$StartTime; EndTime=$EndTime}

    if ($ComputerName) {
        $events = Get-WinEvent -ComputerName $ComputerName -FilterHashTable $FilterHash
    }
    else {
        $events = Get-WinEvent -FilterHashTable $FilterHash
    }

    # Create a hashtable to save counts
    $logoncount = @{}

    # Create an array to save details
    $logons = @()

    foreach ($e in $events)
    {
        # Convert single string into array of string
        $msgarry = $e.Message -split ("`r`n")

        # Pull data out of the array
        foreach ($l in $msgarry)
        {
            # Get username
            if ($l -like "*Account Name:*")
            {
                $x = ($l -split ("`t"))[-1]
            }

            # Get domain
            if ($l -like "*Account Domain:*")
            {
                $y = ($l -split ("`t"))[-1]
            }

            <#
                Get logon type
                2 - interactive (local console)
                3 - network (file share/IIS/etc)
                4 - batch (Scheduled Tasks)
                5 - service
                7 - unlock
                8 - like Type 3, but with clear text credentials
                9 - RunAs - different credentials from logged in user that initiated the program
                10 - RDP
                11 - Cached Credential
            #>
            if ($l -like "*Logon Type:*")
            {
                $type = ($l -split ("`t"))[-1]
            }

            # Get source address
            if ($l -like "*Source Network Address:*")
            {
                $sourceaddress = ($l -split ("`t"))[-1]
            }

            # Dump empty values
            if ($x)
            {
                if (!($x -eq '-'))
                {
                    $uname = $x
                }

                Clear-Variable x
            }

            if ($y)
            {
                if (!($y -eq '-'))
                {
                    $domain = $y
                }

                Clear-Variable y
            }
        }

        # Create new custom object
        $logonobj = New-Object -TypeName psobject
        $logonobj | Add-Member -MemberType NoteProperty -Name UserName -Value $uname
        $logonobj | Add-Member -MemberType NoteProperty -Name Domain -Value $domain
        $logonobj | Add-Member -MemberType NoteProperty -Name LogonType -Value $type
        $logonobj | Add-Member -MemberType NoteProperty -Name SourceAddress -Value $sourceaddress
        $logonobj | Add-Member -MemberType NoteProperty -Name TimeCreated -Value $($e.TimeCreated)

        # Add new object to array
        $logons += $logonobj

        #Clean up all vars
        Clear-Variable uname,domain,type,sourceaddress,logonobj -ErrorAction SilentlyContinue
    }

    if ($Detail)
    {
        return $logons
    }
    else
    {
        foreach ($e in $logons)
        {
            $fullname = $e.Domain + "\" + $e.UserName

            if (!($logoncount.Contains($fullname)))
            {
                $logoncount.Add($fullname, 1)
            }
            else
            {
                $logoncount[$fullname]++
            }
        }

        return $logoncount
    }
}