function Disable-IPv6Bindings
{
    $bindings = Get-NetAdapterBinding -ComponentID 'ms_tcpip6'

    foreach ($b in $bindings)
    {
        if ($b.Enabled -eq 'True')
        {
            Disable-NetAdapterBinding -InputObject $b
        }
    }
}