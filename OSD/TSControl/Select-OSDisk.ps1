$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

#Check if computer is MDT build. Find OSdisk for refresh if it is
if (Get-WmiObject -Query { SELECT * FROM Win32_Volume WHERE Label = 'OSDisk'})
{
    $TSEnv.Value('OSDisk') = (Get-WmiObject -Query { SELECT * FROM Win32_Volume WHERE Label = 'OSDisk'}).DriveLetter
}
#If not MDT build see if we can find the right disk by assuming the volume label is 'Windows'
elseif (Get-WmiObject -Query { SELECT * FROM Win32_Volume WHERE Label = 'Windows'})
{
    $TSEnv.Value('OSDisk') = (Get-WmiObject -Query { SELECT * FROM Win32_Volume WHERE Label = 'Windows'}).DriveLetter
}
#If neither then fail bigly
else
{
    exit 5
}