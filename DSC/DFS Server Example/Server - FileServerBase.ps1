Configuration FileServerBase
{
    Node localhost
    {
        WindowsFeature FileServerInstall
        {
            Ensure = 'Present'
            Name   = 'FS-FileServer'
        }

        WindowsFeature FSRM
        {
            Ensure = 'Present'
            Name   = 'FS-Resource-Manager'
        }

        WindowsFeature BrancheCacheInstall
        {
            Ensure = 'Present'
            Name = 'FS-BranchCache'
        }

        WindowsFeature DedupInstall
        {
            Ensure = 'Present'
            Name = 'FS-Data-Deduplication'
        }
    }
}

$ConfigName = 'FileServerBase'
$ConfigRoot = 'C:\DSCConfig'
# Create and cd to a dedicated config folder
if (!(Test-Path -Path $ConfigRoot))
{
    New-Item -Path $ConfigRoot -ItemType Directory -Force
}

Set-Location -Path $ConfigRoot
FileServerBase #Create the mof file localhost.mof in C:\DSCConfig\FileServerBase
Rename-Item -Path "$ConfigRoot\$ConfigName\localhost.mof" -NewName "$ConfigName.mof"

New-DscChecksum -Path "$ConfigRoot\$ConfigName" #Generate a checksum

#Uncomment to copy files to web root
#$WebRoot = 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
#Copy-Item -Path "$ConfigRoot\$ConfigName\*" -Destination $WebRoot