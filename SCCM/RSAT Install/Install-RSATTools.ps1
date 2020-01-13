# Install GPMC from local repository
param
(
    [Parameter(Mandatory=$true)]
    [ValidateSet('ADUC','Bitlocker','CertificateServices','DHCP','DNS','FailoverCluster','FileServices',
    'GroupPolicy','IPAM','LLDP','NetworkController','NetworkLoadBalancing','RemoteAccess','RemoteDesktop',
    'ServerManager','ShieldedVM','StorageMigrationService','StorageReplica','SystemInsights',
    'VolumeActivation','WSUS','All')]
    [string]$Component,

    [string]$BasePath = '\\dxpe.com\sccm\Config Manager\Resources\Applications\Microsoft\RSAT\Windows 10'
)

# A static table mapping component names from $Component to actual feature names
$featureTable = 
@{
    'ADUC' = 'Rsat.ActiveDirectory.DS-LDS.Tools*';
    'Bitlocker' = 'Rsat.BitLocker.Recovery.Tools*';
    'CertificateServices' = 'Rsat.CertificateServices.Tools*';
    'DHCP' = 'Rsat.DHCP.Tools*';
    'DNS' = 'Rsat.Dns.Tools*';
    'FailoverCluster' = 'Rsat.FailoverCluster.Management.Tools*';
    'FileServices' = 'Rsat.FileServices.Tools*';
    'GroupPolicy' = 'Rsat.GroupPolicy.Management.Tools*';
    'IPAM' = 'Rsat.IPAM.Client.Tools*';
    'LLDP' = 'Rsat.LLDP.Tools*';
    'NetworkController' = 'Rsat.NetworkController.Tools*';
    'NetworkLoadBalancing' = 'Rsat.NetworkLoadBalancing.Tools*';
    'RemoteAccess' = 'Rsat.RemoteAccess.Management.Tools*';
    'RemoteDesktop' = 'Rsat.RemoteDesktop.Services.Tools*';
    'ServerManager' = 'Rsat.ServerManager.Tools*';
    'ShieldedVM' = 'Rsat.Shielded.VM.Tools*';
    'StorageMigrationService' = 'Rsat.StorageMigrationService.Management.Tools*';
    'StorageReplica' = 'Rsat.StorageReplica.Tools*';
    'SystemInsights' = 'Rsat.SystemInsights.Management.Tools*';
    'VolumeActivation' = 'Rsat.VolumeActivation.Tools*';
    'WSUS' = 'Rsat.WSUS.Tools*'
}

# Gather build number to identify correct repository
$buildNum = (Get-CimInstance -ClassName win32_OperatingSystem).BuildNumber
$Path = "$BasePath\$buildNum"

if (!($Component -eq 'All'))
{
    # Use $partialName populated from $featureTable to find current version exact name
    $partialName = $featureTable[$Component]
    $componentName = (Get-WindowsCapability -Online -Name $partialName).Name

}
else
{
    #Install a ton of crap
}