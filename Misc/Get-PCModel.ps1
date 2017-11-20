# Get-PcModel
# Andrew Ogden
# 06/19/17
# Gather PC make/model from a list of computers

param
(
    [array]$ComputerName
)

# Define a variable to store collected data
[array]$ComputerModels = @()

for ($i = 0; $i -lt $ComputerName.Count; $i++)
{
    # Report job status
    Write-Progress -Activity 'Gathering model data' -Status "$($ComputerName[$i]) $($i + 1)/$($ComputerName.Count)" -PercentComplete $($($($i + 1)/$ComputerName.Count) * 100)

    # Assume computer is online
    [bool]$IsOnline = $true

    # Create a custom object
    $Model = New-Object -TypeName psobject
    $Model | Add-Member -MemberType NoteProperty -Name ComputerName -Value $($ComputerName[$i])

    # Gather information
    try
    {
        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $($ComputerName[$i]) -Property Manufacturer,Model -ErrorAction SilentlyContinue
    }
    catch
    {
        # If any error gathering WMI data, assume computer is offline
        [bool]$IsOnline = $false
    }

    # Populate data
    if ($IsOnline -eq $true)
    {
        # Get model
        $Model | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $($ComputerSystem.Manufacturer)

        # If computer is a Lenovo, then we need to get the model name from CSPRoduct.Version
        # instead of CS.Model
        if ($($ComputerSystem.Manufacturer) -eq 'LENOVO')
        {
            $Model | Add-Member -MemberType NoteProperty -Name Model -Value $(Get-WmiObject -Class Win32_ComputerSystemProduct -ComputerName $($ComputerName[$i]) -Property Version).Version
        }
        else
        {
            $Model | Add-Member -MemberType NoteProperty -Name Model -Value $($ComputerSystem.Model)
        }
    }

    # Add results to array
    $ComputerModels += $Model

    # Reset variables
    Clear-Variable -Name ComputerSystem,Model
}

# Return results
return $ComputerModels