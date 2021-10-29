function Invoke-BLEvaluation
{
    param (
        [String][Parameter(Mandatory=$true, Position=1)] $ComputerName,
        [String][Parameter(Mandatory=$False, Position=2)] $BLName
    )
    If ($BLName -eq $Null)
    {
        $Baselines = Get-WmiObject -ComputerName $ComputerName -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration
    }
    Else
    {
        $Baselines = Get-WmiObject -ComputerName $ComputerName -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration | Where-Object {$_.DisplayName -like $BLName}
    }
 
    $Baselines | % { 
        ([wmiclass]"\\$ComputerName\root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version) 
    }
}