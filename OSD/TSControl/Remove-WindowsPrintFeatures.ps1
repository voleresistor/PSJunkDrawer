$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$TargetDisk = $TSEnv.Value('OSDisk')

Get-WindowsOptionalFeature -Path $TargetDisk -FeatureName *print* | Disable-WindowsOptionalFeature -Path $TargetDisk