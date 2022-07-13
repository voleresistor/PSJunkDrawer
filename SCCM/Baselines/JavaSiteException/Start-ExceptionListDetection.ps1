function Start-ExceptionListDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$SiteListLocal = "$env:userprofile\AppData\LocalLow\Sun\Java\Deployment\security",

        [Parameter(Mandatory=$false)]
        [string]$SiteListRemote = "\\puffer.com\netlogon",

        [Parameter(Mandatory=$false)]
        [string]$FileName = "exception.sites",

        [Parameter(Mandatory=$false)]
        [switch]$Remediate
    )

    # If we can access the remote file, attempt remediation
    if ($Remediate)
    {
        # Ensure the path exists
        try {
            New-Item -Path $SiteListLocal -ItemType Directory -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to create local folders."
            exit 4
        }

        # Copy the file
        try {
            Copy-Item -Path "$SiteListRemote\$FileName" -Destination "$SiteListLocal\$FileName" -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to create local file."
            exit 3
        }

        # call ourself again to verify that remediation was successful
        return Start-ExceptionListDetection
    }

    # Does local file exist?
    if (-Not (Test-Path -Path "$SiteListLocal\$FileName")) {
        # Remediation required is true
        return $true
    }

    # Try to get remote file data
    try {
        $objRemoteFileHash = Get-FileHash -Path "$SiteListRemote\$FileName" -Algorithm SHA1 -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to access remote site list."
        exit 1
    }

    # Local file exists so get data
    try {
        $objLocalFileHash = Get-FileHash -Path "$SiteListLocal\$FileName" -Algorithm SHA1 -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to access local site list."
        exit 2
    }

    # Compare files
    if ($objLocalFileHash.Hash -ne $objRemoteFileHash.Hash) {
        # Remediation required is true
        return $true
    }

    # No remediation required
    return $false
}
