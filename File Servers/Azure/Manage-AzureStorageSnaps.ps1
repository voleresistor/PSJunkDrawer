param
(
    [string]$LoginName,
    [string]$PassFile,
    [string]$Subscription,
    [string]$AccountList,
    [switch]$CleanOldSnaps,
    [switch]$CreateSnaps,
    [int]$SnapAge = 14,
    [string]$LogRoot = "\\dxpe.com\dfsa\Logs\Azure\Snapshots",
    [string]$LogLocation = "$LogRoot\$env:ComputerName", # Folder only. Filename is automated
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

    # Clean up sub names for some uses
    $SubFriendly = $Subscription -replace ('\/','')

    if (!(Test-Path -Path $LogLocation))
    {
        New-Item -Path $LogRoot -ItemType Directory -Name $env:ComputerName -Force
    }

    # Log Azure login
    $AdminLog = "$LogLocation\$((Get-DateTimeStamp).Date)_${SubFriendly}_Login.log"
    Write-Log -LogPath $LogPath -Message ">>>>>>>>>> Begin managing snaps at $(Get-Date) <<<<<<<<<<"

    # Login to Azure
    Write-Log -LogPath $AdminLog -Message "Logging into AzureRM..."
    Write-Log -LogPath $AdminLog -Message "`tLoginName: $LoginName"
    Write-Log -LogPath $AdminLog -Message "`tSubscription: $Subscription"
    $AESKey = Get-content -Path $KeyPath
    $passwdText = Get-Content -Path $PassFile
    $securePass = $passwdText | ConvertTo-SecureString -Key $AESKey
    $SnapCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $LoginName,$securePass

    $ctx = Login-AzureRmAccount -Credential $SnapCred -Subscription $Subscription

    if ($ctx)
    {
        Write-Log -LogPath $AdminLog -Message "Login Succeeded!"
    }
    else
    {
        Write-Log -LogPath $AdminLog -Message "Failed to log in using $LoginName"
        return 11
    }
}
process
{
    # Get CSV file
    Write-Log -LogPath $AdminLog -Message "Loading $AccountList..."
    try
    {
        $targetAccounts = Import-Csv -Delimiter ',' -Path $AccountList
    }
    catch
    {
        $Exception = $_.Exception.Message
        Write-Log -LogPath $AdminLog -Message "Failed - $Exception"
    }
    if ((Get-Member -InputObject $targetAccounts).TypeName -eq 'System.Management.Automation.PSCustomObject')
    {
        Write-Log -LogPath $AdminLog -Message "Found 1 entry."
    }
    else
    {
        Write-Log -LogPath $AdminLog -Message "Found $($targetAccounts.Count) entries."
    }

    foreach ($e in $targetAccounts)
    {
        Write-Log -LogPath $AdminLog -Message "Managing storage account: $($e.StorageAccount)"

        # Create a new log file for each account
        $entryLog = "$LogLocation\$((Get-DateTimeStamp).Date)_${SubFriendly}_$($e.StorageAccount).log"
        Write-Log -LogPath $entryLog -Message ">>>>>>>>>> Begin managing $($e.StorageAccount) <<<<<<<<<<"

        # Get the Storage Account
        Write-Log -LogPath $entryLog -Message "Getting Storage Account: $($e.StorageAccount)"
        try
        {
            $StorageAcct = Get-AzureRmStorageAccount -ResourceGroupName $($e.ResourceGroup) -Name $($e.StorageAccount)
        }
        catch
        {
            $Exception = $_.Exception.Message
            Write-Log -LogPath $entryLog -Message "Failed - $Exception"
        }

        # Gather list of shares in current Storage Account
        Write-Log -LogPath $entryLog -Message "Getting shares for Storage Account: $($e.StorageAccount)"
        try
        {
            $FileShares = Get-AzureStorageShare -Context $StorageAcct.Context | Where-Object {$_.IsSnapshot -eq $false}
        }
        catch
        {
            $Exception = $_.Exception.Message
            Write-Log -LogPath $entryLog -Message "Failed - $Exception"
        }
        Write-Log -LogPath $entryLog -Message "Found $($FileShares.Count) shares."

        # Manage snaps for each share
        foreach ($share in $FileShares)
        {
            $DiscoveredSnaps = Get-AzureStorageShare -Context $StorageAcct.Context | Where-Object {($_.IsSnapshot -eq $true) -and ($_.Name -eq $share.Name)}
            Write-Log -LogPath $entryLog -Message "Found $($DiscoveredSnaps.Count) snaps for share: $($share.Name)"

            # Manage existing snaps
            if ($CleanOldSnaps)
            {
                Write-Log -LogPath $entryLog -Message "Begin cleaning up snaps for $($share.Name)"

                foreach ($snap in $DiscoveredSnaps)
                {
                    # Ignore AzureBackup snaps
                    if ($snap.MetaData.Initiator -eq 'AzureBackup')
                    {
                        Write-Log -LogPath $entryLog -Message "Skipping Azure Backup snap created on $($snap.Snapshottime.LocalDateTime) by 'AzureBackup' for share $($snap.Name)"
                        continue
                    }

                    # Remove the auto generated backups.
                    # Need to figure out if these can be configured somewhere
                    if ($snap.MetaData.Initiator -eq 'AzureFilesync')
                    {
                        Write-Log -LogPath $entryLog -Message "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) by AzureFilesync for share $($snap.Name)"
                        try
                        {
                            Remove-AzureStorageShare -Share $snap #-WhatIf
                        }
                        catch
                        {
                            $Exception = $_.Exception.Message
                            Write-Log -LogPath $entryLog -Message "Failed - $Exception"
                        }

                        #Write-Log -LogPath $entryLog -Message "Skipping AzureFilesync snap created on $($snap.Snapshottime.LocalDateTime) by 'AzureFileSync' for share $($snap.Name)"
                        #continue
                    }

                    # Remove snaps older than $SnapAge
                    if ($($snap.SnapshotTime.LocalDateTime) -lt $((Get-Date).AddDays(-$SnapAge)))
                    {
                        Write-Log -LogPath $entryLog -Message "Removing snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"

                        try
                        {
                            Remove-AzureStorageShare -Share $snap #-WhatIf
                        }
                        catch
                        {
                            $Exception = $_.Exception.Message
                            Write-Log -LogPath $entryLog -Message "Failed - $Exception"
                        }
                    }
                    else
                    {
                        Write-Log -LogPath $entryLog -Message "Keeping snapshot created at $($snap.SnapshotTime.LocalDateTime) for share $($snap.Name)"
                    }
                }
            }

            # Create snaps for each share
            if ($CreateSnaps)
            {
                try
                {
                    $s = Get-AzureStorageShare -Context $StorageAcct.Context -Name $share.Name
                    $newSnap = $s.Snapshot()
                    Write-Log -LogPath $entryLog -Message "Created snapshot for $($share.Name) at $($newSnap.SnapshotTime.LocalDateTime)"
                    Clear-Variable -Name newSnap
                }
                catch
                {
                    $Exception = $_.Exception.Message
                    Write-Log -LogPath $entryLog -Message "Failed creating snap - $Exception"
                }
                finally
                {
                    Clear-Variable -Name s
                }
            }
        }
    }
}
end
{
    #Log out of AzureRM
    if ($ctx)
    {
        Write-Log -LogPath $AdminLog -Message "Logging out..."
        Logout-AzureRmAccount
    }

    # End log
    Write-Log -LogPath $AdminLog -Message "Done managing snaps at $(Get-Date)"
}