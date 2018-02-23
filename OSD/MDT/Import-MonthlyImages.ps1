function Import-MonthlyImages
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [string]$ImageSource = '\\dxpe.com\sccm\MDT\Development\Captures',
        [string]$ImageRepo = '\\dxpe.com\sccm\MDT\Source\OS Captures',
        [string]$DeploymentShare = '\\houmdt03.dxpe.com\dsdev$'
    )

    function Compare-Images
    {
        param
        (
            [string]$ImRegEx,
            [string]$ImageRepo
        )

        $ImageMatches = Get-ChildItem -Path $ImageRepo | Where-Object {$_.Name -match $ImageRegEx}
        $NewestImage = $ImageMatches[0]
        foreach ($Image in $ImageMatches)
        {
            if ($Image.LastWriteTime -gt $NewestImage.LastWriteTime)
            {
                $NewestImage = $Image
            }
        }

        return $($NewestImage.Name)
    }

    function Update-OldImages
    {
        param
        (
            [string]$ImRegEx,
            [string]$ImageRepo,
            [string]$NewestImage,
            [string]$Destination,
            [ValidateSet("Move", "Delete")]
            [string]$Action
        )

        foreach ($File in (Get-ChildItem -Path "$ImageRepo" | Where-Object {$_.Name -match $ImageRegex}))
        {
            if (!($File.Name -eq $NewestImage))
            {
                if ($Action -eq 'Move')
                {
                    Move-Item -Path $File.FullName -Destination "$Destination"
                }
                elseif ($Action -eq 'Delete')
                {
                    Remove-Item -Path $File.FullName
                }
            }
        }
    }

    # Load MDT snap-in
    if (!(Get-PSSnapin -Name Microsoft.Bdd.PSSnapin -ErrorAction SilentlyContinue))
    {
        Write-Verbose -Message "MDT Snap-In not found"
        Write-Verbose -Message "Attempting to load MDT Snap-In"
        try
        {
            Add-PSSnapin -Name Microsoft.Bdd.PSSnapin
        }
        catch
        {
            Write-Error -Message "Snap-in loading failed."
            return 1
        }
    }
    Write-Verbose -Message "MDT Snap-In loaded"

    # Ensure drive is mounted
    Restore-MDTPersistentDrive
    $DriveName = Get-MDTPersistentDrive | Where-Object {$_.Path -eq $DeploymentShare} # Not being very generic here

    # Move files around
    $BaseRegex = "-[0-9]{4}\.[0-9]{1,2}\.wim"
    $NewImages = Get-ChildItem -Path $ImageSource
    Write-Verbose -Message "Found $($NewImages.Count) image(s) to copy"

    $i = 1
    foreach ($Image in $NewImages)
    {
        # Copy files to repo
        Write-Progress -Activity "Copying new image files" -Status "Copying new file... ($i/$($NewImages.Count))" -PercentComplete (($i/$($NewImages.Count)) * 100 )

        Write-Verbose -Message "Moving $($Image.FullName) to $ImageRepo\Current Production"
        Move-Item -Path $Image.FullName -Destination "$ImageRepo\Current Production"

        #Read-Host -Prompt "Press [ENTER] to continue:"

        # Move old images to backup
        Write-Progress -Activity "Copying new image files" -Status "Moving old files... ($i/$($NewImages.Count))" -PercentComplete (($i/$($NewImages.Count)) * 100 )
        Write-Verbose -Message "Copying older images for $($($Image.Name -split $BaseRegex)[0]) to $ImageRepo\Backup"
        $ImageRegex = $($Image.Name -split $BaseRegex)[0] + $BaseRegex
        $NewestImage = Compare-Images -ImRegEx $ImageRegex -ImageRepo "$ImageRepo\Current Production"
        Update-OldImages -ImRegEx $ImageRegex -ImageRepo "$ImageRepo\Current Production" -Destination "$ImageRepo\Backup" -NewestImage $NewestImage -Action 'Move'

        #Read-Host -Prompt "Press [ENTER] to continue:"

        # Clean up backup folder
        Write-Progress -Activity "Copying new image files" -Status "Pruning older files... ($i/$($NewImages.Count))" -PercentComplete (($i/$($NewImages.Count)) * 100 )
        Write-Verbose -Message "Pruning older images in $($($Image.Name -split $BaseRegex)[0]) to $ImageRepo\Backup"
        $NewestImage = Compare-Images -ImRegEx $ImageRegex -ImageRepo "$ImageRepo\Backup"
        Update-OldImages -ImRegEx $ImageRegex -ImageRepo "$ImageRepo\Backup" -NewestImage $NewestImage -Action 'Delete'

        #Read-Host -Prompt "Press [ENTER] to continue:"
        $i++
    }

    # Upload images
    foreach ($Image in $NewImages)
    {
        # Build path within deployment share
        $i = 1
        $OSName = $($Image.Name -split ('-'))[0]
        switch ($OSName)
        {
            'Win7Ent' { $OSType = "$($DriveName.Name):\Operating Systems\OS Development\Windows 7"}
            'Win10' { $OSType = "$($DriveName.Name):\Operating Systems\OS Development\Windows 10"}
            'Win2012R2' { $OSType = "$($DriveName.Name):\Operating Systems\OS Development\Windows 2012"}
            'Win2016Std' { $OSType = "$($DriveName.Name):\Operating Systems\OS Development\Windows 2016"}
            'Win2016StdCore' { $OSType = "$($DriveName.Name):\Operating Systems\OS Development\Windows 2016"}
        }

        Write-Progress -Activity "Copying new image files" -Status "Importing $($Image.BaseName) into MDT..." -PercentComplete (($i/$($NewImages.Count)) * 100 )
        Write-Verbose -Message "Importing $($Image.BaseName) into MDT"
        $LongName = Import-MDTOperatingsystem -Path $OSType -SourceFile "$ImageRepo\Current Production\$($Image.Name)" -DestinationFolder $($Image.BaseName)
        Rename-Item -Path "$OSType\$($LongName.Name)" -NewName $($Image.BaseName)

        $i++
    }

    # There's more to do here, but this is a good start
    # Look at browsing the Operating System folder within the deploment share
    # Some way to match imported image to old copy to move old copy to archive?
    # http://systemscenter.ru/mdt2012.en/index.html?page=importmdtoperatingsystem.htm
}