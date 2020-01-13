function Disable-HyperVDefaultSwitch
{
    $HVDefaultSwitch = Get-NetAdapter -Name 'vEthernet (Default Switch)'

    if ($HVDefaultSwitch.Status -eq 'Up')
    {
        Disable-NetAdapter -InputObject $HVDefaultSwitch -Confirm:$false
    }
}