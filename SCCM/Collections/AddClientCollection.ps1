Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1")
$SiteCode = Get-PSDrive -PSProvider CMSITE

$Collection = "Test - Tier 1"
$ComputerName = "HOUSAV01"

$IsMember = Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceId $(get-cmdevice -Name $ComputerName).ResourceID

If (!(Get-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceId $(get-cmdevice -Name $ComputerName).ResourceID)) 
{
    Add-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceId $(get-cmdevice -Name $ComputerName).ResourceID
}

