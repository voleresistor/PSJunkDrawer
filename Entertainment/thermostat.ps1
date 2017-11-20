[CmdletBinding()]
param
(
    [int]$Clicks,
    [int]$Start = 70,
    [int]$Upper = 80,
    [int]$Lower = 60
)

if ($Clicks -ne 0)
{
    # Get the absolute change within the available range
    $Clicks = $Clicks % ($Upper - $Lower)

    # We might need to wrap back around if we count too high...
    if ($Start + $Clicks -gt $Upper)
    {
        return $Lower + (($Start + $Clicks) - $Upper)
    }
    # ...or too low
    elseif ($Start + $Clicks -lt $Lower)
    {
        return $Upper - ($Lower - ($Start + $Clicks))
    }
    else
    {
        return $Start + $Clicks
    }
}
else
{
    return $Start
}