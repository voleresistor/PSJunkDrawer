function Get-ApproxOSDiskSize
{
    $OSDisk = Get-Volume -DriveLetter C

    # 15gb or less
    if ($OSDisk.SizeRemaining -le 16106127360)
    {
        return 'Less than 15.0 GB'
    }
    # 15gb to 100gb
    elseif ($OSDisk.SizeRemaining -le 107374182400)
    {
        return 'Less than 100.0 GB'
    }
    # over 100gb
    else
    {
        return 'Greater than 100.0 GB'
    }
}

Get-ApproxOSDiskSize