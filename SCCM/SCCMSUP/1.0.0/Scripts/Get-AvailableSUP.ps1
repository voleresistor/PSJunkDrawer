function Get-AvailableSUP
{
    <#
    .SYNOPSIS
    Get list of currently actionable Software Updates.

    .DESCRIPTION
    Displays all currently actionable updates in Softare Center on a remote computer and their state.

    .PARAMETER ComputerName
    The name of the remote computer.

    .EXAMPLE
    Get-AvailableSUP -ComputerName pc001.test.local

    .NOTES
        FileName: Get-AvailableSUP.ps1
        Original Author: Andrew Ogden
        Original Contact: andrew.ogden@dxpe.com
        Created: 2020-01-14

        ChangeLog:
        
    #>
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    begin
    {
        <#
            Verify that we can talk to WSMan on the remote computer
            PowerShell CIM cmdlets use WSMan to talk to the remote computer on the following ports:
            47001 - Local listener
            5985 - HTTP
            5986 - HTTPS

            Source:
            https://morgansimonsen.com/2009/12/10/winrm-and-tcp-ports/

            TODO:
            Verify this in MS docs
        #>
        if ((Test-Netconnection -ComputerName $ComputerName -Port 5985).TcpTestSucceeded -eq $false)
        {
            throw "Can't open TCP connection to WSMan on remote computer $ComputerName"
            #return $null
        }

        <#
            A simple hashtable of EvalState codes converted to human text for reporting purposes
            Source:
            https://docs.microsoft.com/en-us/configmgr/develop/reference/core/clients/sdk/ccm_softwareupdate-client-wmi-class
        #>
        $StateHash = @{
            0 = "None";
            1 = "Available";
            2 = "Submitted";
            3 = "Detecting";
            4 = "PreDownload";
            5 = "Downloading";
            6 = "Wait Install";
            7 = "Installing";
            8 = "Pending Soft Reboot";
            9 = "Pending Hard Reboot";
            10 = "Wait Reboot";
            11 = "Verifying";
            12 = "Install Complete";
            13 = "Error";
            14 = "Wait Service Window";
            15 = "Wait User Logon";
            16 = "Wait User Logoff";
            17 = "Wait Job User Logon";
            18 = "Wait User Reconnect";
            19 = "Pending User Logoff";
            20 = "Pending Update";
            21 = "Waiting Retry";
            22 = "Wait Presentation Mode Off";
            23 = "Wait For Orchestration"
        }
    }

    process
    {
        # Gather data from remote computer
        $apps = Get-CimInstance -ComputerName $ComputerName -Namespace 'root\ccm\ClientSDK' -ClassName 'CCM_SoftwareUpdate'

        # Covert data to a custom object to make Eval State human readable
        $supList = @()
        ForEach ($s in $apps)
        {
            $sup = New-Object -TypeName psobject
            $sup | Add-Member -MemberType noteproperty -Name Name -Value $s.Name
            $sup | Add-Member -MemberType noteproperty -Name EvalState -Value $($StateHash[[int]$s.EvaluationState])
            $sup | Add-Member -MemberType noteproperty -Name ArticleID -Value $s.ArticleID
            $sup | Add-Member -MemberType noteproperty -Name UpdateID -Value $s.UpdateID
            $sup | Add-Member -MemberType noteproperty -Name URL -Value $s.URL
            $sup | Add-Member -MemberType noteproperty -Name PSComputerName -Value $s.PSComputerName

            $supList += $sup
            Clear-Variable -Name sup
        }
    }

    end
    {
        return $supList
    }
}