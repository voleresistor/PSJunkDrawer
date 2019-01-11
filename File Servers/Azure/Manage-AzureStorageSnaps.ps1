param
(
    [string]$LoginName,
    [string]$PassFile,
    [string]$StorageAccount,
    [string[]]$ExcludeAccounts = @(),
    [string]$FileShare, # Can take a wildcard
    [switch]$CleanOldSnaps,
    [switch]$CreateSnaps,
    [int]$SnapAge = 14,
    [string]$LogLocation = "\\dxpe.com\dfsa\Logs\Azure\Snapshots\$env:ComputerName", # Folder only. Filename is automated
    [string]$ResourceGroupName = 'TestStorageAccount',
    [string]$KeyPath = '\\dxpe.com\dfsa\Scripts\Azure\key.txt'
)

begin
{
    # Log writing function
    function Write-Log
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory=$true,Position=2)]
            [string]$LogPath,

            [Parameter(Mandatory=$true,Position=1)]
            [string]$Message,

            [Parameter(Mandatory=$false)]
            [string]$TimeStamp = (Get-DateTimeStamp).Time,

            [Parameter(Mandatory=$false)]
            [string]$Datestamp = (Get-DateTimeStamp).Date,

            [Parameter(Mandatory=$false)]
            [string]$Component,

            [Parameter(Mandatory=$false)]
            [string]$Context,

            [Parameter(Mandatory=$false)]
            [ValidateSet('Info','Warning','Error','Verbose')]
            [string]$Type = 'Info',

            [Parameter(Mandatory=$false)]
            [string]$Thread,

            [Parameter(Mandatory=$false)]
            [string]$File
        )

        # Formatted to be easily parsed by cmtrace.exe
        $LogMessage = "<![LOG[$Message]LOG]!><time=`"$TimeStamp`" date=`"$DateStamp`" component=`"$Component`" context=`"$Context`" type=`"$Type`" thread=`"$Thread`" file=`"$File`">"

        # Introduce some extremely simple error checking
        # This means we'll have to do something with the return value in the calling script
        try
        {
            Add-Content -Value $LogMessage -Path $LogPath -ErrorAction Stop
            Start-Sleep -Milliseconds 250
        }
        catch
        {
            Write-Verbose -Message $_.Exception.Message
            Start-Sleep -Milliseconds 250
        }
    }

    function Get-DateTimeStamp
    {
        [CmdletBinding()]
        param
        (
            [int]$HoursAgo,
            [int]$DaysAgo
        )

        # Convert everything to hours
        if ($DaysAgo)    
        {
            $HoursAgo = $DaysAgo * 24
        }

        # Don't forget that we can just get right now
        if (!($HoursAgo))
        {
            $HoursAgo = 0
        }

        # Format the time
        [datetime]$DateTime = (Get-Date).AddDays(-$HoursAgo)
        $TimeStamp = "$($DateTime.Hour):$($DateTime.Minute):$($DateTime.Second).$($DateTime.Millisecond)+000"

        # Format the date
        $Month = "{0:D2}" -f $($DateTime.Month)
        $Day = "{0:D2}" -f $($DateTime.Day)
        $DateStamp = "$Month-$Day-$($DateTime.Year)"

        $MyDate = New-Object -TypeName psobject
        $MyDate | Add-Member -MemberType NoteProperty -Name Date -Value $DateStamp
        $MyDate | Add-Member -MemberType NoteProperty -Name Time -Value $TimeStamp

        # Return custom object with date and time stamp formatted for cmtrace logging
        return $MyDate
    }

    # Log initialization
    $LogPath = "$LogLocation\$((Get-DateTimeStamp).Date).log"
    Write-Log -LogPath $LogPath -Message ">>>>>>>>>> Begin managing snaps at $(Get-Date) <<<<<<<<<<"

    # Login to Azure
    Write-Log -LogPath $LogPath -Message "Logging into AzureRM as $LoginName..."
    $AESKey = Get-content -Path $KeyPath
    $passwdText = Get-Content -Path $PassFile
    $securePass = $passwdText | ConvertTo-SecureString -Key $AESKey
    $SnapCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $LoginName,$securePass

    $ctx = Login-AzureRmAccount -Credential $SnapCred

    if ($ctx)
    {
        Write-Log -LogPath $LogPath -Message "Logged into $($ctx.Name)"
    }
    else
    {
        Write-Log -LogPath $LogPath -Message "Failed to log in using $LoginName"
        return 11
    }
}
process
{
    # Get specified storage account(s)
    if ($StorageAccount)
    {
        $StorageAcct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccount
    }
    else
    {
        $StorageAcct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName | Where-Object {$ExcludeAccounts -notcontains $_.StorageAccountName}
    }

    # Take action on each storage account
    foreach ($sa in $StorageAcct)
    {
        Write-Host "Getting shares for Storage Account: $($sa.StorageAccountName)"
        Write-Log -LogPath $LogPath -Message "Getting shares for Storage Account: $($sa.StorageAccountName)"

        # Collect requested shares from current storage account
        if ($FileShare)
        {
            $FileShares = Get-AzureStorageShare -Context $sa.Context | Where-Object {($_.IsSnapshot -eq $false) -and ($_.Name -like $FileShare)}
        }
        else
        {
            $FileShares = Get-AzureStorageShare -Context $sa.Context | Where-Object {$_.IsSnapshot -eq $false}
        }

        # Gather all snapshots for a storage account
        foreach ($share in $FileShares)
        {
            $DiscoveredSnaps = Get-AzureStorageShare -Context $sa.Context | ?{($_.IsSnapshot -eq $true) -and ($_.Name -eq $share.Name)}
            Write-Host "Found $($DiscoveredSnaps.Count) snaps for share: $($share.Name)"
            Write-Log -LogPath $LogPath -Message "Found $($DiscoveredSnaps.Count) snaps for share: $($share.Name)"

            # Manage existing snaps
            if ($CleanOldSnaps)
            {
            Write-Host "Begin cleaning up snaps for $($share.Name)"
            Write-Log -LogPath $LogPath -Message "Begin cleaning up snaps for $($share.Name)"

            foreach ($snap in $DiscoveredSnaps)
            {
                # Ignore AzureBackup snaps
                if ($snap.MetaData.Initiator -eq 'AzureBackup')
                {
                    Write-Host "Skipping Azure Backup snap created on $($snap.Snapshottime.LocalDateTime) by AzureBackup for share $($snap.Name)"
                    Write-Log -LogPath $LogPath -Message "Skipping Azure Backup snap created on $($snap.Snapshottime.LocalDateTime) by 'AzureBackup' for share $($snap.Name)"
                    continue
                }

                # Remove the auto generated backups.
                # Need to figure out if these can be configured somewhere
                if ($snap.MetaData.Initiator -eq 'AzureFilesync')
                {
                    Write-Host "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) by AzureFilesync for share $($snap.Name)"
                    Write-Log -LogPath $LogPath -Message "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) by AzureFilesync for share $($snap.Name)"
                    Remove-AzureStorageShare -Share $snap #-WhatIf
                    continue
                }

                # Remove snaps older than $SnapAge
                if ($($snap.SnapshotTime.LocalDateTime) -lt $((Get-Date).AddDays(-$SnapAge)))
                {
                    Write-Host "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"
                    Write-Log -LogPath $LogPath -Message "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"
                    Remove-AzureStorageShare -Share $snap #-WhatIf
                }
                else
                {
                    Write-Host "Keeping snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"
                    Write-Log -LogPath $LogPath -Message "Keeping snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"
                }
            }
        }

            # Create snaps for each share
            if ($CreateSnaps)
            {
                $s = Get-AzureStorageShare -Context $sa.Context -Name $share.Name
                $newSnap = $s.Snapshot()
                Write-Host "Created snapshot for $($share.Name) at $($newSnap.SnapshotTime.LocalDateTime)"
                Write-Log -LogPath $LogPath -Message "Created snapshot for $($share.Name) at $($newSnap.SnapshotTime.LocalDateTime)"
            }
        }
    }
}
end
{
    #Log out of AzureRM
    if ($ctx)
    {
        Write-Log -LogPath $LogPath -Message "Logging out of $($ctx.Name)..."
        Logout-AzureRmAccount
    }

    # End log
    Write-Log -LogPath $LogPath -Message "Done managing snaps at $(Get-Date)"
}