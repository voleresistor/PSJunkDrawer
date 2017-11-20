# New-Homedir

function New-HomeDir
{
    param
    (
        [string]$Path,
        [string]$UserName,
        [string]$DomainName
    )
    try
    {
        try
        {
            Import-Module -Name "$PSScriptRoot\NTFSSecurity\4.2.3\NTFSSecurity.psm1" -Force
        }
        catch
        {
            Write-Host 'Unable to import NTFSSecurity module.'
            return 'Failed!'
        }
        
        if (!(Test-Path -Path "$Path\$UserName"))
        {
            try
            {
                New-Item -Path $Path -Name $UserName -ItemType Directory | Out-Null
            }
            catch
            {
                Write-Host 'Unable to create new homedir.'
                return 'Failed!'
            }
            
            try
            {
                Set-NTFSOwner -Path "$Path\$UserName" -Account "$DomainName\$UserName"
            }
            catch
            {
                Write-Host 'Unable to set folder ownership.'
            }
        
            Set-NTFSInheritance -Path "$Path\$UserName" -AccessInheritanceEnabled $false -ErrorAction SilentlyContinue
            Set-NTFSInheritance -Path "$Path\$UserName" -AccessInheritanceEnabled $true -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Host 'Homedir already exists!'
            return 'Failed!'
        }
        
        return 'Done!'
    }
    finally
    {
        Remove-Module -Name 'NTFSSecurity'
    }
}

$stateText = 'Ready.'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$objForm = New-Object System.Windows.Forms.Form
$objForm.Text = 'Create New Homedir'
$objForm.Size = New-Object System.Drawing.Size(300,300)
$objForm.StartPosition = 'CenterScreen'

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {
        $stateText = 'Working...'
        $objStateLabel.Text = $stateText
        $objForm.Refresh()
        $stateText = (New-HomeDir -Path $objRootBox.Text -UserName $objUserBox.Text -DomainName $objDomainBox.Text)
        $objStateLabel.Text = $stateText
        $objForm.Refresh()
    }})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(113,220)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "Create"
$OKButton.Add_Click(
    {
        $stateText = 'Working...'
        $objStateLabel.Text = $stateText
        $objForm.Refresh()
        $stateText = (New-HomeDir -Path $objRootBox.Text -UserName $objUserBox.Text -DomainName $objDomainBox.Text)
        $objStateLabel.Text = $stateText
        $objForm.Refresh()
    })
$objForm.Controls.Add($OKButton)

#$CancelButton = New-Object System.Windows.Forms.Button
#$CancelButton.Location = New-Object System.Drawing.Size(150,220)
#$CancelButton.Size = New-Object System.Drawing.Size(75,23)
#$CancelButton.Text = 'Cancel'
#$CancelButton.Add_Click({$objForm.Close()})
#$objForm.Controls.Add($CancelButton)

$objRootLabel = New-Object System.Windows.Forms.Label
$objRootLabel.Location = New-Object System.Drawing.Size(10,20)
$objRootLabel.Size = New-Object System.Drawing.Size(280,20)
$objRootLabel.Text = 'Homedir root path:'
$objForm.Controls.Add($objRootLabel)

$objRootBox = New-Object System.Windows.Forms.TextBox
$objRootBox.Location = New-Object System.Drawing.Size(10,40)
$objRootBox.Size = New-Object System.Drawing.Size(260,20)
$objRootBox.Text = '\\dxpe.com\homedir\DXPE'
#$objRootBox.Text = 'C:\temp\homedir'
$objForm.Controls.Add($objRootBox)

$objUserLabel = New-Object System.Windows.Forms.Label
$objUserLabel.Location = New-Object System.Drawing.Size(10,70)
$objUserLabel.Size = New-Object System.Drawing.Size(280,20)
$objUserLabel.Text = 'User name:'
$objForm.Controls.Add($objUserLabel)

$objUserBox = New-Object System.Windows.Forms.TextBox
$objUserBox.Location = New-Object System.Drawing.Size(10,90)
$objUserBox.Size = New-Object System.Drawing.Size(260,20)
$objForm.Controls.Add($objUserBox)

$objDomainLabel = New-Object System.Windows.Forms.Label
$objDomainLabel.Location = New-Object System.Drawing.Size(10,120)
$objDomainLabel.Size = New-Object System.Drawing.Size(280,20)
$objDomainLabel.Text = 'Domain name:'
$objForm.Controls.Add($objDomainLabel)

$objDomainBox = New-Object System.Windows.Forms.TextBox
$objDomainBox.Location = New-Object System.Drawing.Size(10,140)
$objDomainBox.Size = New-Object System.Drawing.Size(260,20)
$objDomainBox.Text = 'dxpe.corp'
$objForm.Controls.Add($objDomainBox)

$objStateLabel = New-Object System.Windows.Forms.Label
$objStateLabel.Location = New-Object System.Drawing.Size(10,170)
$objStateLabel.Size = New-Object System.Drawing.Size(280,20)
$objStateLabel.Text = $stateText
$objForm.Controls.Add($objStateLabel)

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()