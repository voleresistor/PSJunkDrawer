function Show-Spinner($Message, $Type = 'star')
{
    if ($Type -eq 'star')
    {
        $a = @('/','-','\','|','/','-','\','|')
        $typeCount = 8
    }
    if ($Type -eq 'square')
    {
        $specialChar = [char]8254
        $a = @('|  ',' _ ','  |'," $specialChar ")
        $typeCount = 4
    }
    if ($Type -eq 'dots')
    {
        $a = @('.','..','...','....','    ')
        $typeCount = 5
    }
    
    $i = 0
    
    try
    {                  
        while ($i -lt $typeCount)
        {
            if ($Type -eq 'dots')
            {
                Write-Host " $Message$($a[$i])`r" -NoNewline
            }
            else
            {
                Write-Host " $($a[$i]) $Message`r" -NoNewline
            }
            
            Start-Sleep -Milliseconds 500
            if ($i -eq ($typeCount - 1))
            {
                $i = 0
            }
            else
            {
                $i++
            }
        }
    }
    finally
    {
        Write-Host "`r`n"
    }
}