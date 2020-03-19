function New-DFSNBackupSet {
    [CmdletBinding(SupportsShouldProcess=$true)]
    <#
    #>

    param (
        [Parameter(ParameterSetName='Standalone', Mandatory=$true)]
        [string]$DfsnServer,

        [Parameter(ParameterSetName='Domain', Mandatory=$true)]
        [string]$DfsnDomain,

        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )

    begin {
        # Try to load DFSN module before anything else. No reason to continue if we can't query the roots
        try {
            Import-Module -Name DFSN -Function 'Get-DfsnRoot'
            Write-Verbose 'DFSN module imported.'
        }
        catch {
            Write-Error "Couldn't load module DFSN. Do you have DFS RSAT tools installed?"
            Write-Error $_.Exception.Message
            break
        }

        # Verify that dfsutil is available
        $DFSUtil = "$env:systemroot\System32\dfsutil.exe"
        if (!(Test-Path -Path $DFSUtil -ErrorAction SilentlyContinue)) {
            Write-Error "Can't find dfsutil."
            break
        }
        Write-Verbose "DFSUtil found at $DFSUtil."

        # Make sure the backup path is present and writable
        if (Test-Path -Path $BackupPath -ErrorAction SilentlyContinue) {
            try {
                $TempFile = "$BackupPath\tempfile.tmp"
                [io.file]::Create($TempFile).Close()
                [io.file]::Delete($TempFile)
                Write-Verbose "$BackupPath appears writable."
            }
            catch {
                Write-Error "Backup path not writeable."
                Write-Error $_.Exception.Message
                break
            }
        }
        else {
            Write-Error "Backup location inaccessible. Check path or permissions."
            break
        }

        # Create new folder for backup set
        $BackupFolder = $(Get-Date -UFormat "%m%d%y")
        $BackupPath += "\$BackupFolder"
        if (!(Test-Path -Path "$BackupPath" -ErrorAction SilentlyContinue)) {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
            Write-Verbose "New folder created for backup set. $BackupPath."
        }
        else {
            Write-Error "Backup folder already exists. You must manually delete and re-run this script."
            Write-Error $BackupPath
            break
        }

        # Gather the roots
        try {
            if ($DfsnDomain) {
                $Roots = (Get-DfsnRoot -Domain $DfsnDomain)
            }
            else {
                $Roots = (Get-DfsnRoot -Server $DfsnServer)
            }

            Write-Verbose "$($Roots.Count) roots found on $DfsnDomain$DfsnServer."
            foreach ($root in $Roots) {
                Write-Verbose $($root.Path)
            }
        }
        catch {
            Write-Error "Can't query DFS roots."
            Write-Error $_.Exception.Message
            break
        }
    }
    process {
        # Take the backups
        foreach ($root in $Roots) {
            if ($PSCmdlet.ShouldProcess($($root.Path), "Export root to XML file")) {
                $ExportFile = "$($root.Path -replace('\\','') -replace('\.','')).xml"
                $ExportArgs = "root export $($root.Path) $BackupPath\$ExportFile"
                Start-Process -FilePath $DFSUtil -ArgumentList $ExportArgs -NoNewWindow -Wait
            }
        }
    }
}