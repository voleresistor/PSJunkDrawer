$matchString = "\\\\\.\\F:\\Departments2\\Accounting\\B27 \(Syteline Accounting Files\)\\Month End Syteline Documentation\\Subledgers\\11-18."
$sourcePath = "F:\Departments2\Accounting\DfsrPrivate\ConflictAndDeleted"
$destPath = "C:\temp\recover"

foreach ($f in ($a.ConflictAndDeletedManifest.Resource))
{
    if ($f.Path -match $matchString)
    {
        $originalName = ($f.Path -split("\\"))[-1]

        if ($f.Path -like "*E-Dash Details*")
        {
            Write-Host $($f.Path)
            Copy-Item -Path "$sourcePath\$($f.NewName)" -Destination "$destPath\E-Dash Details\$originalName"
        }
        else
        {
            Write-Host $($f.Path)
            Copy-Item -Path "$sourcePath\$($f.NewName)" -Destination "$destPath\$originalName"
        }
    }
}