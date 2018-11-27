function Get-SubFolderSize
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    function Get-UncPath
    {
        param
        (
            [Parameter(Mandatory=$true)]
            [string]$Path
        )
        
        # Path needs conversion to UNC format
        if ($Path -match "[a-z]\:\\[.]{0,}")
        {
            return "\\?\" + $Path
        }

        return $Path
    }

    $Shares = @()
    foreach ($s in (Get-childItem -Path (Get-UncPath -Path $Path) -Directory))
    {
        $objShare = new-object -TypeName psobject
        $objShare | Add-Member -MemberType NoteProperty -Name Share -Value $($s.BaseName)
    
        $i = 0
    
        foreach ($f in (ls -Path $s.FullName -File -Recurse))
        {
            $i += $f.Length
        }
    
        $j = $i / 1gb
        $objShare | Add-Member -membertype NoteProperty -Name Size -Value $j
    
        $Shares += $objShare
    }
    
    return $Shares
}