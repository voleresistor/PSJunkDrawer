Function Get-SCCMObjectLocation
{
    <# 
        .SYNOPSIS 
            Get folder location of SCCM object.
        .DESCRIPTION
            Returns the folder location of the given SCCM object.
        .PARAMETER  SMSId 
            The ID of the object to query.
        .PARAMETER  SiteCode
            Specify the site code on the targeted server.
        .PARAMETER  SiteServerName
            Specify the name of the site server to query.
        .Notes 
            Author : Antoine DELRUE 
            WebSite: http://obilan.be 
    #>

    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]$SMSId,

        [string]$SiteCode = (Get-CMSite).SiteCode,

        [string]$SiteServerName = (Get-CMSite).ServerName
    )

    #Find the container directly containing the item
    $ContainerItem = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServerName -Query "select * from SMS_ObjectContainerItem where InstanceKey = '$($SMSId)'"
    If (!$ContainerItem) {
        $ObjectName = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServerName -Query "select * from SMS_ObjectName where ObjectKey = '$($SMSId)'"
        If (!$ObjectName) {
            Write-Warning "No object or containers found for $SMSId"
            break;
        }
        Else
        {
            Return "root\$(($ObjectName).Name)"
            break;
        }
    }

    If ($ContainerItem -is [array]) {
        Write-Warning "Multiple objects with ID: $SMSId"
        Foreach ($Item In $ContainerItem) {
            $tempOutputString = Get-SCCMContainerHierarchy -ContainerNodeId $Item.ContainerNodeID -ObjectType $Item.ObjectType -ObjectTypename $Item.ObjectTypeName -SiteCode $SiteCode -SiteServerName $SiteServerName
            $OutputString = "$OutputString`nroot\$tempOutputString"
        }
        Return "$OutputString"
    }
    Else {
        #One object found
        $OutputString = Get-SCCMContainerHierarchy -ContainerNodeId ($ContainerItem).ContainerNodeID -SiteCode $SiteCode -SiteServerName $SiteServerName
        Return "root\$OutputString"
    }   
}