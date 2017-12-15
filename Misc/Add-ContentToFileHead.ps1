function Add-ContentToFileHead
{
    <#
    .SYNOPSIS
    Add content to the head of a file.
    
    .DESCRIPTION
    Companion to Add-Content. Adds content to head of file, rather than appending to the end.
    
    .PARAMETER FileName
    The name and path of the file to be modified.
    
    .PARAMETER Value
    The value to add to the head of the file.
    
    .EXAMPLE
    Add-ContentToFileHead -Path C:\temp\testfile.csv -Value 'Date,ComputerName,OperatingSystem'

    Add a header to an existing CSV file.
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string]$FileName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$Value
    )

    Begin
    {
        # Do as much work as possible in temp files to limit risk to data
        $NewTmp = New-TemporaryFile
        $OldTmp = New-TemporaryFile
    }
    Process
    {
        # Populate NewTmp with header and old data
        Add-Content -Value $Value -Path $($NewTmp.FullName)
        Add-Content -Value $(Get-Content $FileName) -Path $($NewTmp.FullName)

        Move-Item -Path $FileName -Destination $($OldTmp.FullName) -Force
        Copy-Item -Path $($NewTmp.FullName) -Destination $FileName
    }
    End
    {
        if (((Get-Item -Path $NewTmp.FullName).Length -gt (Get-Item -Path $OldTmp.FullName).Length) -and ((Get-Item -Path $NewTmp.FullName).Length -eq (Get-Item -Path $FileName).Length))
        {
            Remove-Item -Path $($OldTmp.FullName) -Force
            Remove-Item -Path $($NewTmp.FullName) -Force
            return $true
        }
        else
        {
            throw 'File lengths are inconsistent with expected values.'
            Write-Host "Data may be located in the following files:"
            Write-Host "`t$($NewTmp.FullName)"
            Write-Host "`t$($OldTmp.FullName)"
            return $false
        }
    }
}