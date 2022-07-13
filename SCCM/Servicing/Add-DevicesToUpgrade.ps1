function Add-DevicesToUpgrade {
    param(
        [string[]]$InputObject,
        [string]$CollectionName = 'Prod - Windows 10 20H2 - Servicing'
    )
    $TargetCollection = Get-CMDeviceCollection -Name $CollectionName
    foreach ($o in $InputObject) {
        $item = Get-CMDevice -Name $o
        if ($item) {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionId $TargetCollection.CollectionID -ResourceId $item.ResourceId
            Clear-Variable item
        }
        else {
            Write-Warning "$o not found in CM"
        }
    }
    Get-CMCollectionMember -CollectionId $TargetCollection.CollectionID
}