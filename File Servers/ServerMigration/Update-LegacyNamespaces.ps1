param
(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$TemplateFile,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$Server
)

<#
    .Synopsis
    Update legacy namespaces from a template file.
    
    .Description
    Update all legacy namespaces on the given server from a template file.
    
    .Parameter TemplateFile
    Path to the XML template file.

    .Parameter Server
    Name of the legacy root server to update.
    
    .Example
    Update-LegacyNamespaces.ps1 -TemplateFile c:\temp\legacy.xml -Server Houdfs04.dxpe.com
    
    Update all legacy roots on Houdfs04.dxpe.com using legacy.xml.
#>

$Namespaces = Get-DfsnRoot -ComputerName $Server
$Template = Get-Content -Path $TemplateFile

foreach ($t in $Namespaces)
{
    Write-Host $t.Path
    $NSName = ($t.Path -split ('\\'))[-1]
    $FileName = $NSName -replace ('#', '')
    Write-Host $NSName
    Write-Host $FileName
    
    Add-Content -Value $((Get-Content -Path $TemplateFile -First 4).Replace('Test', $NSName)) -Path "C:\temp\rootreplace\$FileName.xml"
    Add-Content -Value ($Template[4..$($Template.Count)]) -Path "C:\temp\rootreplace\$FileName.xml"

    Start-Process -FilePath 'dfsutil.exe' -ArgumentList "/root:$($t.Path) /Import:C:\temp\rootreplace\$FileName.xml /Set" -NoNewWindow -Wait
}