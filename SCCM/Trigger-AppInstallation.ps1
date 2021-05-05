Function Trigger-AppInstallation
{
    # Taken entrely from:
    # https://timmyit.com/2016/08/08/sccm-and-powershell-force-installuninstall-of-available-software-in-software-center-through-cimwmi-on-a-remote-client/

    Param
    (
        [String][Parameter(Mandatory=$True, Position=1)] $Computername,
        [String][Parameter(Mandatory=$True, Position=2)] $AppName,
        [ValidateSet("Install","Uninstall")]
        [String][Parameter(Mandatory=$True, Position=3)] $Method
    )
    
    Begin
    {
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
        #Write-Host $Application
        #return 0

        $Args = @{
            EnforcePreference = [UINT32] 0
            Id = "$($Application.id)"
            IsMachineTarget = $Application.IsMachineTarget
            IsRebootIfNeeded = $False
            Priority = 'High'
            Revision = "$($Application.Revision)"
        }
    }
    
    Process
    {
        Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Args
    }
    
    End {}
 
}