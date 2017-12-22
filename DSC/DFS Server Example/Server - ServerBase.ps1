Configuration ServerBase
{
    Node localhost
    {
        WindowsFeature RemoveSMB1
        {
            Ensure = 'Absent'
            Name   = 'FS-SMB1'
        }
    }
}

$ConfigName = 'ServerBase'
$ConfigRoot = 'C:\DSCConfig'
# Create and cd to a dedicated config folder
if (!(Test-Path -Path $ConfigRoot))
{
    New-Item -Path $ConfigRoot -ItemType Directory -Force
}

Set-Location -Path $ConfigRoot
ServerBase #Create the mof file localhost.mof in C:\DSCConfig\FileServerBase
Rename-Item -Path "$ConfigRoot\$ConfigName\localhost.mof" -NewName "$ConfigName.mof"

New-DscChecksum -Path "$ConfigRoot\$ConfigName" #Generate a checksum

#Uncomment to copy files to web root
#$WebRoot = 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
#Copy-Item -Path "$ConfigRoot\$ConfigName\*" -Destination $WebRoot