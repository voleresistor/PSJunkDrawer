function Connect-MEMDrive {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [parameter(Mandatory=$false, HelpMessage=”Site server where the SMS Provider is installed.”)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [string]$SiteServer = 'bry-cm-0001.puffer.com',

        [parameter(Mandatory=$false, HelpMessage=”Show a progressbar displaying the current operation.”)]
        [switch]$ShowProgress
    )

    # Determine SiteCode from WMI 
    try { 
        Write-Verbose -Message “Determining Site Code for Site server: ‘$($SiteServer)'”
        $SiteCodeObjects = Get-WmiObject -Namespace “root\SMS” -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) { 
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) { 
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message “Site Code: $($SiteCode)” 
            } 
        } 
    } 
    catch [System.UnauthorizedAccessException] { 
        Write-Warning -Message “Access denied”
        break 
    } 
    catch [System.Exception] {
        Write-Warning -Message “Unable to determine Site Code”
        break
    } 
    # Load assemblies 
    try { 
        Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath “Microsoft.ConfigurationManagement.ApplicationManagement.dll”) -ErrorAction Stop
        Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath “Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll”) -ErrorAction Stop
        Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath “Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll”) -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message “Access denied”
        break
    } 
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message
        break
    } 
    # Load ConfigMgr module 
    try { 
        $SiteDrive = $SiteCode + “:”
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    } 
    catch [System.UnauthorizedAccessException] { 
        Write-Warning -Message “Access denied”
        break
    }
    catch [System.Exception] {
        try {
            Import-Module -Name (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath “\ConfigurationManager.psd1”) -Force -ErrorAction Stop -Verbose:$false 
            if ((Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) { 
                New-PSDrive -Name $SiteCode -PSProvider “AdminUI.PS.Provider\CMSite” -Root $SiteServer -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
        catch [System.UnauthorizedAccessException] { 
            Write-Warning -Message “Access denied”
            break
        } 
        catch [System.Exception] {
            Write-Warning -Message “$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)”
            break 
        }
    }

    # Determine and set location to the CMSite drive 
    $CurrentLocation = $PSScriptRoot 
    Set-Location -Path $SiteDrive -ErrorAction Stop -Verbose:$false
    
    # Disable Fast parameter usage check for Lazy properties 
    $CMPSSuppressFastNotUsedCheck = $true 
}

function Copy-NewImages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=1)]
        [string]$SourcePath = 'C:\OSDBuilder\OSMedia',

        [Parameter(Mandatory=$false, Position=2)]
        [string]$DestPath = '\\bry-cm-0001\applications$\Image\WIM'
    )

    # Verify Source
    try {
        $objSrc = Get-Item -Path $SourcePath -ErrorAction Stop
    }
    catch {
        #Write-Error $_.Exception.Message
        Write-Error "Can't verify access to source path: $SourcePath"
        return
    }

    # Verify Destination
    try {
        $objDst = Get-Item -Path $DestPath -ErrorAction Stop
    }
    catch {
        #Write-Error $_.Exception.Message
        Write-Error "Can't verify access to destination path: $DestPath"
        return
    }

    # Try to mount the drive
    try {
        $objOldPath = Get-Location
        Connect-MEMDrive
        $objMemPath = Get-Location
        Set-Location -Path $($objOldPath.Path)
    }
    catch {
        Write-Error $_.Exception.Message
        Write-Error "Can't mount MEM drive."
        return
    }

    # Get all images in source
    $arrImages = Get-ChildItem -Path $($objSrc.FullName) -Directory

    # Process souce images
    foreach ($f in $arrImages) {
        # Create destintion directories
        try {
            $strNewFolder = "$($objDst.FullName)\$($f.Name)"
            Write-Verbose "New folder path: $strNewFolder"
            if (!(Test-Path -Path $strNewFolder)) {
                New-Item -Path $strNewFolder -Force -ItemType Directory -ErrorAction Stop
            }
        }
        catch {
            Write-Error $_.Exception.Message
            Write-Error "Unable to create destination folder: $strNewFolder"
            return
        }

        # Copy files
        try {
            $strSrcFile = "$($f.FullName)\OS\Sources\install.wim"
            Start-BitsTransfer -Source $strSrcFile -Destination $strNewFolder -DisplayName "Copy Imges" -Description $($f.Name) -ErrorAction Stop
        }
        catch {
            #Write-Error $_.Exception.Message
            Write-Error "Unable to copy install.wim ($strSrcFile) to destination folder: $strNewFolder"
            return
        }

        # Create a new CMOSImage
        try {
            Set-Location -Path $($objMemPath.Path)
            $($f.Name) -match " [0-9]{5}\.[0-9]{1,4}$" | Out-Null
            $strVers = $Matches[0].TrimStart()
            $strName = ($($f.Name) -split ($strVers))[0]
            $strDesc = "Updated $(get-date -UFormat "%B %Y")"
            $objOSImage = New-CMOperatingSystemImage -Description $strDesc -Name $strName -Path "$strNewFolder\install.wim" -Version $strVers -Confirm:$false
            Start-CMContentDistribution -OperatingSystemImage $objOSImage -DistributionPointGroupName 'On Prem'
            Set-Location -Path $($objOldPath.Path)
        }
        catch {
            Write-Error $_.Exception.Message
            #Write-Error "Unable to create new image"
            return
        }
    }

    # Reset PS location
    Set-Location -Path $($objOldPath.Path)
}