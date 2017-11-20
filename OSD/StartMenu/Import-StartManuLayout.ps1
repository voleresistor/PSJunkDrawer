<#
    Solution: OSD
    Purpose: Import custom Win10 Start layouts
    Version: 2.0 02/16/17

    Author: Andrew Ogden
    Email: aogden@dxpe.com
#>

param
(
    #Define what input is accepted in this switch
    [ValidateSet('Office2016','Office2013','Training')]
    [string]$StartMenuType
)

#Set our layout file name depending on the given switch
switch ($StartMenuType)
{
    'Office2013'
    {
        $LayoutFile = 'Office2013_StartLayout.xml'
    }

    'Office2016'
    {
        $LayoutFile = 'Office2016_StartLayout.xml'
    }

    'Training'
    {
        $LayoutFile = 'Training_StartLayout.xml'
    }
}

#Copy IE link to local computer for adding IE to Start Menu
Copy-Item -Path "$PSScriptRoot\Internet Explorer.lnk" -Destination "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories"

#Import custom Start Menu
#Note: This only affects new user logins
Import-StartLayout -LayoutPath "$PSScriptRoot\$LayoutFile" -MountPath $env:SystemDrive\