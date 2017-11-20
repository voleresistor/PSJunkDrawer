param
(
    [string]$GroupName = 'IT Department',
    [string]$FileName = 'C:\temp\GroupExport.csv'
)

$property = @()
$recurseGroups = $false
#$GroupName = $null
#$FileName = $null

# Create popup box for user options
Function ShowDialog(){
    [VOID][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    
    # create form
    $form = New-Object Windows.Forms.Form
    $form.text = "AD Group to CSV Form"
    $form.top = 10
    $form.left = 10
    $form.height = 250
    $form.width = 325
    
    # create radiobutton
    $dn = New-Object Windows.Forms.CheckBox
    $dn.text = "Distinguished Name"
    $dn.height = 20
    $dn.width = 150
    $dn.top = 20
    $dn.left = 5
    
    # create radiobutton1
    $fn = New-Object Windows.Forms.CheckBox
    $fn.text = "Full Name"
    $fn.height = 20
    $fn.width = 150
    $fn.top = 40
    $fn.left =5
    
    # create radiobutton
    $class = New-Object Windows.Forms.CheckBox
    $class.text = "Object Class"
    $class.height = 20
    $class.width = 150
    $class.top = 60
    $class.left = 5
    
    # create radiobutton2
    $guid = New-Object Windows.Forms.CheckBox
    $guid.text = "Object GUID"
    $guid.height = 20
    $guid.width = 150
    $guid.top = 20
    $guid.left = 155

    # create radiobutton2
    $samaccount = New-Object Windows.Forms.CheckBox
    $samaccount.text = "SAM Account Name"
    $samaccount.height = 20
    $samaccount.width = 150
    $samaccount.top = 40
    $samaccount.left = 155

    # create radiobutton2
    $sid = New-Object Windows.Forms.CheckBox
    $sid.text = "SID"
    $sid.height = 20
    $sid.width = 150
    $sid.top = 60
    $sid.left = 155
    
    # create Groupbox
    $GroupBox0 = New-Object Windows.Forms.GroupBox
    $GroupBox0.Left = 10
    $GroupBox0.Text = "User Properties"
    $GroupBox0.Top = 10
    $GroupBox0.Width = 280
    $GroupBox0.Height = 90
    $GroupBox0.Controls.Add($dn)
    $GroupBox0.Controls.Add($fn)
    $GroupBox0.Controls.Add($class)
    $GroupBox0.Controls.Add($guid)
    $GroupBox0.Controls.Add($samaccount)
    $GroupBox0.Controls.Add($sid)

    #Create Group Name Textbox
    $gntlabel = New-Object Windows.Forms.Label
    $gntlabel.text = "Group Name"
    $gntlabel.height = 12
    $gntlabel.width = 100
    $gntlabel.top = 110
    $gntlabel.left = 10
    $groupNameText = New-Object Windows.Forms.TextBox
    $groupNameText.Text = $GroupName
    $groupNameText.Left = 10
    $groupNameText.Top = 125
    $groupNameText.Width = 170
    $groupNameText.Height = 20

    #Create File Name TextBox
    $fplabel = New-Object Windows.Forms.Label
    $fplabel.text = "File Path"
    $fplabel.height = 12
    $fplabel.width = 100
    $fplabel.top = 160
    $fplabel.left = 10
    $filePathText = New-Object Windows.Forms.TextBox
    $filePathText.Text = $FileName
    $filePathText.Left = 10
    $filePathText.Top = 175
    $filePathText.Width = 170
    $filePathText.Height = 20
    
    # create recurse checkbox
    $recurse = New-Object Windows.Forms.CheckBox
    $recurse.text = "Recurse"
    $recurse.height = 20
    $recurse.width = 150
    $recurse.top = 125
    $recurse.left = 190
        
    # create event handler for button
    $event = {
        if($dn.checked){
            $Script:property += "distinguishedname"
        }
        if($fn.checked){
            $Script:property += "name"
        }
        if($class.checked){
            $Script:property += "objectclass"
        }
        if($guid.checked){
            $Script:property += "objectguid"
        }
        if($samaccount.checked){
            $Script:property += "samaccountname"
        }
        if($sid.checked){
            $Script:property += "sid"
        }
        if (!$Script:property){
            $Script:property = "*"
        }
        if ($groupNameText.Text){
            $Script:GroupName = $groupNameText.Text
        }
        if ($filePathText.Text){
            $Script:FileName = $filePathText.Text
        }
        if ($recurse.checked){
            $Script:recurseGroups = $true
        }
        $form.Close()
    }
    
    # create button
    $button = New-Object Windows.Forms.Button
    $button.Add_Click($event)
    $button.text = "Export"
    $button.height = 30
    $button.width = 75
    $button.top = 170
    $button.left = 190
    $form.controls.add($button)
    
    # attach controls to form
    $form.controls.add($Groupbox0)
    $form.controls.add($Groupbox1)
    $form.controls.add($button)
    $form.controls.add($gntlabel)
    $form.controls.add($groupNameText)
    $form.controls.add($fplabel)
    $form.controls.add($filePathText)
    $form.controls.add($recurse)
    
    [VOID]$form.showdialog()
}

ShowDialog

if ($recurseGroups -eq $true){
    Get-AdGroupMember -Identity $GroupName -Recursive | Select-Object -Property $property | Export-Csv -Path $FileName -NoTypeInformation
} else {
    Get-AdGroupMember -Identity $GroupName | Select-Object -Property $property | Export-Csv -Path $FileName -NoTypeInformation
}