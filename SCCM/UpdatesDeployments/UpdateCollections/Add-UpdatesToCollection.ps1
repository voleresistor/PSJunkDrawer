function Add-UpdatesToCollection
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$SourceCollectionName,

        [Parameter(Mandatory=$true)]
        [string]$DestCollectionName
    )

    # Collect source update IDs
    $sourceUpdates = (Get-CMSoftwareUpdateGroup -Name $SourceCollectionName).Updates

    # Get dest group ID
    $destGroupId = (Get-CMSoftwareUpdateGroup -Name $DestCollectionName).CI_ID

    # Add updates to destination group
    $i = 0
    while ($i -lt ($sourceUpdates).Count)
    {
        $u = $sourceUpdates[$i]
        Write-Progress -Activity "Adding updates to $DestCollectionName" -Status "[$($i + 1)/$($sourceUpdates.Count)] - $((Get-CMSoftwareUpdate -Id $u -Fast).LocalizedDisplayName)" -PercentComplete (($i / $sourceUpdates.Count) *100)
        Add-CMSoftwareUpdateToGroup -SoftwareUpdateId $u -SoftwareUpdateGroupId $destGroupId
        Clear-Variable -Name u
        $i++
    }
}