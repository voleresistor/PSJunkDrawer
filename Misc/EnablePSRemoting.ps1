[CmdletBinding()]
param
(
)

# Store build numbers as variables
$B1607 = 10586
$B1703 = 14393
$B1709 = 16299

# Get this number as an int for easy comparison with above build variables
[int]$BuildNumber = (Get-WmiObject -Class Win32_Operatingsystem).BuildNumber

# If, for example, build 1709 needed different command to enable PsRemoting we can make the changes
# by modifying this script slightly rather than writing a whole new script.
if ($BuildNumber -eq $null)
{
    Enable-PSRemoting -Force
}
else
{
    # In Windows 10, we need to check for and disable public networks temporarily
    # or they may fail this step
    $Public_Interfaces = Get-NetConnectionProfile -NetworkCategory Public -ErrorAction SilentlyContinue
    $Public_Adapters = @()

    foreach ($i in $Public_Interfaces)
    {
        $Public_Adapters += Get-NetAdapter -InterfaceIndex $($i.InterfaceIndex)
    }

    try
    {
        foreach ($a in $Public_Adapters)
        {
            Write-Verbose -Message "Disabling $($a.Name) temporarily while enabling PSRemoting..."
            $a | Disable-NetAdapter -Confirm:$false
        }

        Enable-PsRemoting -Force
    }
    finally
    {
        # Turn those disabled adapters back on no matter what happened
        foreach ($a in $Public_Adapters)
        {
            Write-Verbose -Message "Re-enabling $($a.Name)..."
            $a | Enable-NetAdapter -Confirm:$False
        }
    }
}