function Get-TempDir
{
    $tmpf = New-TemporaryFile
    Remove-Item $($tmpf.FullName)
    return New-Item -Path $($tmpf.Directory) -Name $($tmpf.Name) -ItemType Directory
}

function Compare-GPO
{
    param
    (
        [Parameter(Mandatory=$true)]
        [xml]$Policy1,

        [Parameter(Mandatory=$true)]
        [xml]$Policy2,

        [Parameter(Mandatory=$true)]
        [ValidateSet('User', 'Computer')]
        [string]$CompareNode
    )

    $NodeNames = @{
        'Drive Maps' = 'Extension.DriveMapSettings.Drive.Name';
        'Files' = 'Extension.FilesSettings.File.Name';
        'Folder Redirection' = 'Extension.Folder.Id';
        'Internet Explorer Maintenance' = 'Extension.Type';
        'Internet Options' = '';
        'LanSvc Networks' = 'Extension.Dot3SvcSetting.LanPolicies.Name';
        'Local Users and Groups' = 'Extension.LocalUsersandGroups.Group.Name';
        'Name Resolution Policy' = '';
        'Network Access Protection Client Management' = '';
        'Power Options' = '';
        'Public Key' = 'Extension.Type';
        'Registry' = 'Extension.Policy.Name';
        'Remote Installation' = 'Extension.Type';
        'Scripts' = 'Extension.Script.Command';
        'Security' = 'Extension.SecurityOptions.Display.Name';
        'Services' = '';
        'Shortcuts' = '';
        'Software Installation' = '';
        'Software Restriction' = '';
        'Windows Firewall' = '';
        'Windows Registry' = 'Extension.RegistrySettings.Registry.Name';
        'WLanSvc Networks' = ''
    }

    # Define an array to store potential conflicts
    $PotentialConflicts = @()

    # Nested loop shenanigans to compare everything
    foreach ($n in $NodeNames)
    {
        # Gather matching node types
        $nodeMatches = @()

        if (($Policy1.GPO.$CompareNode.ExtensionData | Where-Object {$_.Name -eq $n}) -and `
            (($Policy2.GPO.$CompareNode.ExtensionData | Where-Object {$_.Name -eq $n})))
        {
            Write-Verbose "Both policies contain a $n node in the $CompareNode node."
            $nodeMatches += $n
        }

        # Compare individual registry entries
        foreach ($m in $nodeMatches)
        {
            Write-Verbose "Comparing $m for $($Policy1.GPO.Name) and $($Policy2.GPO.Name)"
            $pol1Names = ($Policy1.GPO.$CompareNode.ExtensionData | Where-Object {$_.Name -eq $n}).$($NodeNames[$n])
            $pol2Names = ($Policy2.GPO.$CompareNode.ExtensionData | Where-Object {$_.Name -eq $n}).$($NodeNames[$n])
            
            # Log any name match. The user can manually compare settings later
            foreach ($pName in $pol1Names)
            {
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
            $Conflicts += Compare-GPO -Policy1 $opol -Policy2 $ipol -CompareNode Computer
            $Conflicts += Compare-GPO -Policy1 $opol -Policy2 $ipol -CompareNode User

            #Clear-Variable -Name ipol
        }

        #Clear-Variable -Name opol
    }

    $outFile = "$OutFolder\GPOCompare - $(Get-Date -Format '%M-%d-%y').csv"
    #Add-Content -Value 'RefPolName,RefPolId,DiffPolName,DiffPolId,UserOrComputer,NodeType,SettingName' -Path "$outfile"
    #foreach ($e in $Conflicts)
    #{
    #    Add-Content "$($e.RefPolName),$($e.RefPolId),$($e.DiffPolName),$($e.DiffPolId),$($e.UserOrComputer),$($e.NodeType),$($e.SettingName)"
    #}
    $outFile
    return $Conflicts
}