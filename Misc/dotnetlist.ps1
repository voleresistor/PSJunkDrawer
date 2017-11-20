[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

#################
# Create-UIlist #
#################
Function Create-UIList {
param ($Title,$ChoiceQuestion,$Choices)
# Create our form
$MainForm = New-Object System.Windows.Forms.Form 
$MainForm.Text = $Title
$MainForm.Size = New-Object System.Drawing.Size(500,200) 
$MainForm.StartPosition = "CenterScreen"

# Key Handlers for enter & Escape
$MainForm.KeyPreview = $True
$MainForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$Script:UIListResult=$ListBox.SelectedItem;$MainForm.Close()}})
$MainForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$MainForm.Close()}})

# OK button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$Script:UIListResult=$ListBox.SelectedItem;$MainForm.Close()})
$MainForm.Controls.Add($OKButton)

# Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(225,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$MainForm.Close()})
$MainForm.Controls.Add($CancelButton)

# Label
$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(480,20) 
$objLabel.Text = $ChoiceQuestion
$MainForm.Controls.Add($objLabel) 

# Our list box
$ListBox = New-Object System.Windows.Forms.ListBox 
$ListBox.Location = New-Object System.Drawing.Size(10,40) 
$ListBox.Size = New-Object System.Drawing.Size(460,20) 
$ListBox.Height = 80

# Choices for list box
for ($i=0;$i -lt $Choices.Count; $i++) {
[void]$ListBox.Items.Add($Choices[$i])
}


# Add controls for Form & Show it.
$MainForm.Controls.Add($ListBox) 
$MainForm.Topmost = $True
$MainForm.Add_Shown({$MainForm.Activate()})
[void]$MainForm.ShowDialog()
}

$choicesArr = New-Object System.Collections.ArrayList
[void]$ChoicesArr.Add("Do Something")
[void]$ChoicesArr.Add("DO something PRETTY")
[void]$ChoicesArr.Add("DO something else!")

Create-UIList -title "This is a choices list" -choicequestion "please select an option to perform" -choices $choicesarr

switch ($UIListresult) {
   {$_ -eq "Do Something"} { $choice1 = "Doing a thing."; $choice1;}
   {$_ -eq "DO something PRETTY"} {$choice2 = "Doing a PRETTY thing."; $choice2;}
   {$_ -eq "DO something else!"} { $choice3 = "Doing some other thing."; $choice3;}
      
}