function Get-DfsLinkSize
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$OutputFile = "c:\temp\DeptSize_$(Get-Date -Format MM-dd-yy).csv"
    )

    function Get-LinkSize
    {
        param
        (
            [Parameter(Mandatory=$true, Position=1)]
            [string]$Path
        )

        $t = 0
        Get-ChildItem -Path $Path -Recurse | ForEach-Object {$t += $_.Length}
        return $t
    }

    #Initialize output file
    if (!(Test-Path -Path $OutputFile))
    {
        Add-Content -Value 'Root,SizeInGB' -Path $OutPutFile -Force
    }

    $DirectLinks = Get-ChildItem -Path $Path -Attributes ReparsePoint+Directory
    $SubLinks = Get-ChildItem -Path $Path -Attributes !ReparsePoint+Directory

    foreach ($link in $DirectLinks)
    {
        $size = "{0:N2}" -f $($(Get-LinkSize -Path $($link.FullName)) / 1GB)
        Add-Content -Path $OutputFile -Value "$($link.FullName),$size"
    }

    foreach ($link in $SubLinks)
    {
        Get-DfsLinkSize -Path $link.FullName -OutputFile $OutputFile
    }
}