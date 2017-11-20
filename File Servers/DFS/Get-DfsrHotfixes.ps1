param
(
    [array]$ComputerName,
    [array]$HotFixIds
)

function Validate-HotFixIds
{
    param
    (
        [array]$HotFixIds
    )
    
    $tmpIds = @()

    # Validate given hotfixes
    foreach ($h in $HotFixIds)
    {
        if ((!($h -match "KB\d{6,7}")) -and ($h -match "\d{6,7}"))
        {
            $h = "KB$h"
            $tmpIds += $h
        }
        elseif ($h -match "KB\d{6,7}")
        {
            $tmpIds += $h
        }
        else
        {
            Write-Verbose -Message "Dropping $h, which doesn't match the KB pattern."
        }
    }

    return $tmpIds
}

# Check each computer in the list for the given hotfixes
foreach ($c in $ComputerName)
{
    Get-HotFix -Id (Validate-HotFixIds -HotFixIds $HotFixIds) -ComputerName $c
}