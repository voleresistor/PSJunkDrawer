function Add-CISBenchmarkConfig {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$false)]
        [string]$TargetSettingsXML,

        [Parameter(Mandatory=$false)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [string]$Description,

        [Parameter(Mandatory=$false)]
        [string[]]$References,

        [Parameter(Mandatory=$false)]
        [string]$TemplatePath = 'C:\temp\git\PSJunkDrawer\Operating System\WindowsServer\CISBenchmarks\Templates\Template.xml' #"$env:UserProfile\Documents\WindowsPowerShell\Modules\CISBenchmarks\Templates\Template.xml"
    )

    # define Config node
    $arrElementList = @(
	    'name',
	    'description',
        'references'
    )

    # Load file or create new one
    if (!(Test-Path -Path $TargetSettingsXML -ErrorAction SilentlyContinue)) {
        $TargetSettingsXML = $TemplatePath
    }
    try {
        [xml]$xmlTargetSettings = Get-Content -Path $TargetSettingsXML
    }
    catch {
        Write-Error $_.Exception.Message
        Write-Warning "Unable to load XML settings file: $TargetSettingsXML"
    }

    #return $xmlTargetSettings

    # Create the new config node and sub elements
    $objNewElement = $xmlTargetSettings.CreateElement("config")
    $xmlTargetSettings.baselines.configs.AppendChild($objNewElement)

    #return $xmlTargetSettings

    foreach ($strElement in $arrElementList) {
        $objSubElement = $xmlTargetSettings.CreateElement("$strElement")
	    $objNewElement.AppendChild($objSubElement)
        break
    }

    return $xmlTargetSettings

    $xmlTargetSettings.baselines.configs.count += 1

    # Apply settings to the new node
    if ($Name) {
        $objNewElement.name = $Name
    }

    if ($Description) {
        $objNewElement.description = $Description
    }

    # Return modified XML for inspection
    return $xmlTargetSettings
}