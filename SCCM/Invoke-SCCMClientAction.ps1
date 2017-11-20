param
(
    [string]$ComputerName,
    [switch]$AppDeployCycle,
    [switch]$DDRCycle,
    [switch]$FileCollectionCycle,
    [switch]$HardwareInventoryCycle,
    [switch]$MachinePolRetrievalCycle,
    [switch]$MachinePolEvalCycle,
    [switch]$SoftwareInvCycle,
    [switch]$SoftwareMeteringReport,
    [switch]$SoftwareUpdDepCycle,
    [switch]$SoftwareUpdScanCycle,
    [switch]$StateMessageRefresh,
    [switch]$UserPolRetrievalCycle,
    [switch]$UserPolEvalCycle,
    [switch]$WindowsInstallerSourceUpdate
)

Function ShowDialog(){
    # Default window dimensions
    $windowWidth = 350
    $windowHeight = 500
    $stateText = 'Ready.'
    
    # Load forms class
    [VOID][Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    
    # create form
    $objForm = New-Object System.Windows.Forms.Form
    $objForm.Text = 'SMS Client Actions'
    $objForm.Size = New-Object System.Drawing.Size($windowWidth, $windowHeight)
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
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape"){$objForm.Close()}})
    
    # create label
    $objHNLabel = New-Object System.Windows.Forms.Label
    $objHNLabel.Text = 'Hostname:'
    $objHNLabel.Size = New-Object System.Drawing.Size(60, 20)
    $objHNLabel.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40))
    $objForm.Controls.Add($objHNLabel)
    
    # Create hostname field
    $objHostNameBox = New-Object System.Windows.Forms.TextBox
    $objHostNameBox.Location = New-Object System.Drawing.Size(($windowWidth / 25 + 60), ($windowHeight / 40))
    $objHostNameBox.Size = New-Object System.Drawing.Size (200, 20)
    $objHostNameBox.Text = 'localhost'
    $objForm.Controls.Add($objHostNameBox)
    
    # Create checkbox for App Deployment Eval
    $ObjAppDepEvalCyc = New-Object System.Windows.Forms.RadioButton
    $ObjAppDepEvalCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 40))
    $ObjAppDepEvalCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjAppDepEvalCyc.Text = 'Application Deployment Evaluation Cycle'
    $objForm.Controls.Add($ObjAppDepEvalCyc)
    
    # Create checkbox for Discovery Data Collection
    $ObjDDRCyc = New-Object System.Windows.Forms.RadioButton
    $ObjDDRCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 60))
    $ObjDDRCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjDDRCyc.Text = 'Discovery Data Collection Cycle'
    $objForm.Controls.Add($ObjDDRCyc)
    
    # Create checkbox for File Collection
    $ObjFileCollCyc = New-Object System.Windows.Forms.RadioButton
    $ObjFileCollCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 80))
    $ObjFileCollCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjFileCollCyc.Text = 'File Collection Cycle'
    $objForm.Controls.Add($ObjFileCollCyc)
    
    # Create checkbox for Hardware Inventory Cycle
    $ObjHwInvCyc = New-Object System.Windows.Forms.RadioButton
    $ObjHwInvCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 100))
    $ObjHwInvCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjHwInvCyc.Text = 'Hardware Inventory Cycle'
    $objForm.Controls.Add($ObjHwInvCyc)
    
    # Create checkbox for Machine Policy Cycle
    $ObjCompPolCyc = New-Object System.Windows.Forms.RadioButton
    $ObjCompPolCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 120))
    $ObjCompPolCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjCompPolCyc.Text = 'Machine Policy Evaluation Cycle'
    $objForm.Controls.Add($ObjCompPolCyc)
    
    # Create checkbox for Software Inventory Cycle
    $ObjSWInvCyc = New-Object System.Windows.Forms.RadioButton
    $ObjSWInvCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 140))
    $ObjSWInvCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjSWInvCyc.Text = 'Software Inventory Cycle'
    $objForm.Controls.Add($ObjSWInvCyc)
    
    # Create checkbox for Software Metering Cycle
    $ObjSWMetCyc = New-Object System.Windows.Forms.RadioButton
    $ObjSWMetCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 160))
    $ObjSWMetCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjSWMetCyc.Text = 'Software Metering Usage Report Cycle'
    $objForm.Controls.Add($ObjSWMetCyc)
    
    # Create checkbox for Software Update Deployment Cycle
    $ObjSWUpdEvalCyc = New-Object System.Windows.Forms.RadioButton
    $ObjSWUpdEvalCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 180))
    $ObjSWUpdEvalCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjSWUpdEvalCyc.Text = 'Software Update Deployment Evaluation Cycle'
    $objForm.Controls.Add($ObjSWUpdEvalCyc)
    
    # Create checkbox for Software Update Scan Cycle
    $ObjSWUpdScanCyc = New-Object System.Windows.Forms.RadioButton
    $ObjSWUpdScanCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 200))
    $ObjSWUpdScanCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjSWUpdScanCyc.Text = 'Software Update Scan Cycle'
    $objForm.Controls.Add($ObjSWUpdScanCyc)
    
    # Create checkbox for State Message Refresh
    $ObjStateMsgRef = New-Object System.Windows.Forms.RadioButton
    $ObjStateMsgRef.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 220))
    $ObjStateMsgRef.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjStateMsgRef.Text = 'State Message Refresh'
    $objForm.Controls.Add($ObjStateMsgRef)
    
    # Create checkbox for User Policy Retrieval Cycle
    $ObjUsrPolCyc = New-Object System.Windows.Forms.RadioButton
    $ObjUsrPolCyc.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 240))
    $ObjUsrPolCyc.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjUsrPolCyc.Text = 'User Policy Retrieval Cycle'
    $objForm.Controls.Add($ObjUsrPolCyc)
    
    # Create checkbox for User Policy Evaluation Cycle
    $ObjUsrPolEval = New-Object System.Windows.Forms.RadioButton
    $ObjUsrPolEval.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 260))
    $ObjUsrPolEval.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjUsrPolEval.Text = 'User Policy Evaluation Cycle'
    $objForm.Controls.Add($ObjUsrPolEval)
    
    # Create checkbox for Installer Source List Update
    $ObjInstSrcUpd = New-Object System.Windows.Forms.RadioButton
    $ObjInstSrcUpd.Location = New-Object System.Drawing.Size(($windowWidth / 25), ($windowHeight / 40 + 280))
    $ObjInstSrcUpd.Size = New-Object System.Drawing.Size(($windowWidth - 50), 20)
    $ObjInstSrcUpd.Text = 'Windows Installer Source List Update'
    $objForm.Controls.Add($ObjInstSrcUpd)
    
    # Create OK button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size((($windowWidth / 2) - (75 / 2)), ($windowHeight / 40 + 330))
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "Run"
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
    
    # Create State update field
    $objStateLabel = New-Object System.Windows.Forms.Label
    $objStateLabel.Location = New-Object System.Drawing.Size(10, 20)
    $objStateLabel.Size = New-Object System.Drawing.Size(50,30)
    $objStateLabel.Text = $stateText
    
    # Create state update box
    $objStateBox = New-Object System.Windows.Forms.GroupBox
    $objStateBox.Location = New-Object System.Drawing.Size(($windowWidth / 50), ($windowHeight / 40 + 355))
    $objStateBox.Size = New-Object System.Drawing.Size(($windowWidth - 50), 75)
    $objStateBox.Text = 'Process State'
    $objStateBox.Controls.Add($objStateLabel)
    $objForm.Controls.Add($objStateBox)
    
    
    [VOID]$objForm.showdialog()
}

ShowDialog