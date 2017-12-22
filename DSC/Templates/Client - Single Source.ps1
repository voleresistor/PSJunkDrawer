[DscLocalConfigurationManager()]
Configuration MyConfig
{
    Node localhost #This should always be 'localhost' for config name based DSC pull configs.
    {
        Settings
        {
            RefreshFrequencyMins            = 30; 
            RefreshMode                     = "PULL"; #Clients periodically pull configs from server
            ConfigurationMode               ="ApplyAndAutocorrect";
            AllowModuleOverwrite            = $true;
            RebootNodeIfNeeded              = $true;
            ConfigurationModeFrequencyMins  = 60;
        }

        ConfigurationRepositoryWeb PullSrv
        {
            ServerURL                       = 'https://dsc01:8080/PSDSCPullServer.svc' #For lab purposes this is fine. Prefer FQDN in prod
            RegistrationKey                 = '6cf7e4e2-fd19-4e51-9212-bfa831725f10' #This reg key is unique to lab environment
            ConfigurationNames              = @("Config01") #List of config names, separated by commas
            AllowUnsecureConnection         = $false #Allow unsecure comms in cases with bad or no cert
        }
    }
}

# Create and cd to a dedicated config folder
$ConfigRoot = 'C:\DSCConfig'
if (!(Test-Path -Path $ConfigRoot))
{
    New-Item -Path $ConfigRoot -ItemType Directory -Force
}

Set-Location -Path $ConfigRoot
MyConfig #Create the mof file localhost.meta.mof in C:\DSCConfig\MyConfig

#Uncomment to automatically apply config if running in elevated console
#Set-DSCLocalConfigurationManager localhost -Path C:\DSCConfig\MyConfig -Verbose