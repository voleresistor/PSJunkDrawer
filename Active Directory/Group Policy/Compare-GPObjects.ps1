function Get-TempDir
{
    $tmpf = New-TemporaryFile
    Remove-Item $($tmpf.FullName)
    return New-Item -Path $($tmpf.Directory) -Name $($tmpf.Name) -ItemType Directory
}

function Compare-ComputerGPO
{
    param
    (
        [Parameter(Mandatory=$true)]
        [xml]$Policy1,

        [Parameter(Mandatory=$true)]
        [xml]$Policy2
    )

    # Define an array to store potential conflicts
    $PotentialConflicts = @()

    # If both pols contain Computer extensiondata compare them
    if ($Policy1.GPO.Computer.ExtensionData -and $Policy2.GPO.Computer.ExtensionData)
    {
        Write-Verbose "Both policies contain a Computer node."
        # Nested loop shenanigans to compare everything
        foreach ($n in $Policy1.GPO.Computer.ExtensionData.Name)
        {
            # Check Windows Registry node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
                (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
                ($n -eq 'Windows Registry'))
            {
                Write-Verbose "Both policies contain a Windows Registry node."
                $pol1Names = ($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}).Extension.RegistrySettings.Registry.Name
                $pol2Names = ($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}).Extension.RegistrySettings.Registry.Name

                # Compare individual registry entries
                foreach ($pName in $pol1Names)
                {
                    Write-Verbose "Checking for $pName in $($Policy2.GPO.Name)"
                    # Log any name match. The user can manually compare settings later
                    if ($pol2Names -contains $pName)
                    {
                        Write-Verbose "Found $pName in $($Policy2.GPO.Name)"
                        $conflict = New-Object -TypeName psobject
                        $conflict | Add-Member -MemberType NoteProperty -Name RefPolName -Value $($Policy1.GPO.Name)
                        $conflict | Add-Member -MemberType NoteProperty -Name RefPolId -Value $($Policy1.GPO.Identifier.Identifier.'#text')
                        $conflict | Add-Member -MemberType NoteProperty -Name DiffPolName -Value $($Policy2.GPO.Name)
                        $conflict | Add-Member -MemberType NoteProperty -Name DiffPolId -Value $($Policy2.GPO.Identifier.Identifier.'#text')
                        $conflict | Add-Member -MemberType NoteProperty -Name UserOrComputer -Value 'Computer'
                        $conflict | Add-Member -MemberType NoteProperty -Name NodeType -Value $n
                        $conflict | Add-Member -MemberType NoteProperty -Name SettingName -Value $($pName)
                        $PotentialConflicts += $conflict
                    }
                }
            }

            # Check Registry node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Registry'))
            {}

            # Check Drive Maps node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Drive Maps'))
            {}

            # Check Files node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Files'))
            {}

            # Check Folder Redirection node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Folder Redirection'))
            {}

            # Check Internet Explorer Maintenance node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Internet Explorer Maintenance'))
            {}

            # Check Internet Options node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Internet Options'))
            {}

            # Check LanSvc Networks node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'LanSvc Networks'))
            {}

            # Check Local Users and Groups node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Local Users and Groups'))
            {}

            # Check Name Resolution Policy node type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Resolution Policy'))
            {}

            # Check Network Access Protection Client Management node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Network Access Protection Client Management'))
            {}

            # Check Power Options node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Power Options'))
            {}

            # Check Public Key node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Public Key'))
            {}

            # Check Remote Installation node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Remote Installation'))
            {}

            # Check Scripts node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Scripts'))
            {}

            # Check Security node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Security'))
            {}

            # Check Services node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Services'))
            {}

            # Check Shortcuts node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Shortcuts'))
            {}

            # Check Software Installation node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Software Installation'))
            {}

            # Check Software Restriction node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Software Restriction'))
            {}

            # Check Windows Firewall node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Windows Firewall'))
            {}

            # Check WLanSvc Networks node Type
            if (($Policy1.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.Computer.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'WLanSvc Networks'))
            {}
        }
    }

    # Pass our findings back to the caller
    return $PotentialConflicts
}

function Compare-UserGPO
{
    param
    (
        [Parameter(Mandatory=$true)]
        [xml]$Policy1,

        [Parameter(Mandatory=$true)]
        [xml]$Policy2
    )

    # Define an array to store potential conflicts
    $PotentialConflicts = @()

    # If both pols contain User extensiondata compare them
    if ($Policy1.GPO.User.ExtensionData -and $Policy2.GPO.User.ExtensionData)
    {
        Write-Verbose "Both policies contain a User node."
        # Nested loop shenanigans to compare everything
        foreach ($n in $Policy1.GPO.User.ExtensionData.Name)
        {
            # Check Windows Registry node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
                (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
                ($n -eq 'Windows Registry'))
            {
                Write-Verbose "Both policies contain a Windows Registry node."
                $pol1Names = ($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}).Extension.RegistrySettings.Registry.Name
                $pol2Names = ($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}).Extension.RegistrySettings.Registry.Name

                # Compare individual registry entries
                foreach ($pName in $pol1Names)
                {
                    Write-Verbose "Checking for $pName in $($Policy2.GPO.Name)"
                    # Log any name match. The user can manually compare settings later
                    if ($pol2Names -contains $pName)
                    {
                        Write-Verbose "Found $pName in $($Policy2.GPO.Name)"
                        $conflict = New-Object -TypeName psobject
                        $conflict | Add-Member -MemberType NoteProperty -Name RefPolName -Value $($Policy1.GPO.Name)
                        $conflict | Add-Member -MemberType NoteProperty -Name RefPolId -Value $($Policy1.GPO.Identifier.Identifier.'#text')
                        $conflict | Add-Member -MemberType NoteProperty -Name DiffPolName -Value $($Policy2.GPO.Name)
                        $conflict | Add-Member -MemberType NoteProperty -Name DiffPolId -Value $($Policy2.GPO.Identifier.Identifier.'#text')
                        $conflict | Add-Member -MemberType NoteProperty -Name UserOrComputer -Value 'User'
                        $conflict | Add-Member -MemberType NoteProperty -Name NodeType -Value $n
                        $conflict | Add-Member -MemberType NoteProperty -Name SettingName -Value $($pName)
                        $PotentialConflicts += $conflict
                    }
                }
            }

            # Check Registry node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Registry'))
            {}

            # Check Drive Maps node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Drive Maps'))
            {}

            # Check Files node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Files'))
            {}

            # Check Folder Redirection node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Folder Redirection'))
            {}

            # Check Internet Explorer Maintenance node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Internet Explorer Maintenance'))
            {}

            # Check Internet Options node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Internet Options'))
            {}

            # Check LanSvc Networks node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'LanSvc Networks'))
            {}

            # Check Local Users and Groups node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Local Users and Groups'))
            {}

            # Check Name Resolution Policy node type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Resolution Policy'))
            {}

            # Check Network Access Protection Client Management node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Network Access Protection Client Management'))
            {}

            # Check Power Options node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Power Options'))
            {}

            # Check Public Key node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Public Key'))
            {}

            # Check Remote Installation node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Remote Installation'))
            {}

            # Check Scripts node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Scripts'))
            {}

            # Check Security node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Security'))
            {}

            # Check Services node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Services'))
            {}

            # Check Shortcuts node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Shortcuts'))
            {}

            # Check Software Installation node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Software Installation'))
            {}

            # Check Software Restriction node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Software Restriction'))
            {}

            # Check Windows Firewall node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'Windows Firewall'))
            {}

            # Check WLanSvc Networks node Type
            if (($Policy1.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.User.ExtensionData | Where-Object {$_.Name -eq $n})) -and `
            ($n -eq 'WLanSvc Networks'))
            {}
        }
    }

    # Pass our findings back to the caller
    return $PotentialConflicts
}

function Export-GPObjects
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$DomainName
    )

    # Get all group policy objects
    $GPObjects = Get-Gpo -Domain $DomainName -All

    # Create temp dir for XML exports
    $tempDir = Get-TempDir
    Write-verbose "Temp Directory: $($tempDir.FullName)"

    # List policies to verbose output and export them to a temp folder
    foreach ($pol in $GPObjects)
    {
        Write-Verbose "Exporting policy $($pol.DisplayName) with GUID: $($pol.Id)"
        Get-GpoReport -Guid $($pol.Id) -ReportType Xml | Out-File -FilePath "$($tempDir.FullName)\$($pol.Id).xml"
    }

    return $tempDir
}

function Compare-GPObjects
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$false)]
        [string]$OutFolder = "C:\temp\polcompare",

        [Parameter(Mandatory=$false)]
        [string[]]$ComparePols
    )

    # Export all GPOs into a temp dir
    $tempDir = Export-GPObjects -DomainName $DomainName

    # Do stuff
    $GPOExports = Get-ChildItem -Path $tempDir
    $Conflicts = @()
    for ($i = 0; $i -lt ($GPOExports).Count; $i++)
    {
        [xml]$opol = Get-Content -Path "$(($GPOExports[$i]).FullName)"

        for ($j = ($i + 1); $j -lt ($GPOExports).Count; $j++)
        {
            $ipolPath = $(($GPOExports[$j]).FullName)
            [xml]$ipol = Get-Content -Path $ipolPath
            Write-Verbose "Compare policy $($GPOExports[$i].BaseName) with $($GPOExports[$j].BaseName)"
            $Conflicts += Compare-ComputerGPO -Policy1 $opol -Policy2 $ipol

            #Clear-Variable -Name ipol
        }

        #Clear-Variable -Name opol
    }

    $outFile = "$OutFolder\GPOCompare - $(Get-Date -Format '%M-%d-%y').csv"
    Add-Content -Value 'RefPolName,RefPolId,DiffPolName,DiffPolId,UserOrComputer,NodeType,SettingName' -Path "$outfile"
    foreach ($e in $Conflicts)
    {
        Add-Content "$($e.RefPolName),$($e.RefPolId),$($e.DiffPolName),$($e.DiffPolId),$($e.UserOrComputer),$($e.NodeType),$($e.SettingName)"
    }

    return $Conflicts
    $outFile
}