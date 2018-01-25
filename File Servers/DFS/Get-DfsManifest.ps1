function Get-DfsManifest
{
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ManifestPath
    )

    # Test for access to manifest
    if (!(Test-Path -Path $ManifestPath))
    {
        throw "$ManifestPath not found."
    }

    # Gather manifest as XML
    [Xml]$ManiXml = Get-Content -Path $ManifestPath

    # Read XML properties to determine if ConflictAndDeleted or PreExisting
    $ManiType = ($ManiXml | Get-Member -Type Property | Where-Object {$_.Name -ne 'xml'}).Name

    # Build array of custom objects to return manifest information
    $ManifestContents = @()
    
    foreach ($Entry in $ManiXml.$ManiType.Resource)
    {
        $ManiObj = New-Object -TypeName psobject
        $ManiObj | Add-Member -MemberType NoteProperty -Name Path -Value $Entry.Path
        $ManiObj | Add-Member -MemberType NoteProperty -Name NewName -Value $Entry.NewName
        $ManiObj | Add-Member -MemberType NoteProperty -Name Time -Value $Entry.Time
        $ManiObj | Add-Member -MemberType NoteProperty -Name Files -Value $Entry.Files
        $ManiObj | Add-Member -MemberType NoteProperty -Name Size -Value $Entry.Size

        $ManifestContents += $ManiObj
    }

    return $ManifestContents
}