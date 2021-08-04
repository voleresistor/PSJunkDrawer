function Get-AdObjectAcl {
    <##>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "The full distinguished name of an AD object."
        )]
        [string[]]$DistinguishedName,

        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "The server name to query for object ACLs. Defaults to DNS domain of current user."
        )]
        [string]$ServerName = $env:USERDNSDOMAIN,

        [Parameter(
            Mandatory = $false,
            Position = 3,
            HelpMessage = "The port on which to connect to the server."
        )]
        [ValidateSet(389, 636)]
        [int]$Port = 389
    )

    #Requires -Modules ActiveDirectory

    begin {
        #Import AD module
        if (-not(Get-Module -Name ActiveDirectory -ErrorAction Stop)) {
            try {
                Import-Module -Name ActiveDirectory
            }
            catch {
                $_.Exception.Message
                $success = $false
            }
        }
        # Verify that the AD PSDrive was mounted
        # $success = $true
        # if (-not (Get-PSDrive -Name AD -PSProvider ActiveDirectory -ErrorAction SilentlyContinue)) {
        #     Write-Verbose "AD drive not mounted!"
        #     $success = $false
        # }
        # else {
        #     Write-Verbose "AD drive mounted successfully."
        # }
    }

    process {
        if ($success) {
            # do things
            foreach ($dn in $DistinguishedName) {
                try {
                    Get-Acl -Path "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$dn" -ErrorAction Stop
                }
                catch {
                    $_.Exception.Message
                    Write-Warning "Couldn't get ACL for $dn"
                    continue
                }
            }
        }
    }

    end {
        # Clean up the mounted drive if it's still mounted
        # This may rename itself? Add logic to handle that if it appears to happen again
        if (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue) {
            Write-Verbose "Removing AD module..."
            Remove-Module -Name ActiveDirectory
        }
    }
}