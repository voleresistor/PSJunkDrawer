function Get-SurnameAlphaCount
{
    param
    (
        [string]$DomainName = $env:UserDNSDomain
    )

    $Surnames = (get-aduser -Filter {Enabled -eq $true} -Properties Surname)
    $counts = @{}
    $finalCounts = @()

    foreach ($n in $Surnames.Surname)
    {
        if ($n -ne $null)
        {
            $firstLetter = ($n.ToLower())[0]
        }

        if ($firstLetter -ne $null -and $counts.Contains($firstLetter) -and $firstLetter -match "[a-z]")
        {
            $counts[$firstLetter] ++
        }
        else
        {
            $counts.Add($firstLetter, 1)
        }
    }

    foreach ($i in $counts.Keys)
    {
        $x = New-Object -TypeName psobject
        $x | Add-Member -MemberType NoteProperty -Name 'Letter' -Value $i
        $x | Add-Member -MemberType NoteProperty -Name 'Count' -Value $Counts[$i]
        $finalCounts += $x
    }

    return $finalCounts
}