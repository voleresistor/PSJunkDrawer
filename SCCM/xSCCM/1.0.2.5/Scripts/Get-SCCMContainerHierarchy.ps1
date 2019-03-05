Function Get-SCCMContainerHierarchy
{
    <# 
        .SYNOPSIS 
            Get folder location of SCCM collection.
        .DESCRIPTION
            Returns the folder location of the given SCCM collection.
        .PARAMETER  ContainerNodeId 
            The ID of the collection to query.
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
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ContainerNodeId,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$SiteCode = (Get-CMSite).SiteCode,

        [Parameter(Mandatory=$true,Position=2)]
        [string]$SiteServerName = (Get-CMSite).ServerName,

        [Parameter(Mandatory=$false)]$ObjectType = ($ContainerItem).ObjectType,

        [Parameter(Mandatory=$false)]$ObjectTypeName = ($ContainerItem).ObjectTypeName
    )
    
    Switch ($ObjectType)
    {
        2       {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMPackage -ID $SMSId).Name} # Package
        14      {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMOperatingSystemInstaller -ID $SMSId).Name} # OS Install Package
        18      {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMOperatingSystemImage -ID $SMSId).Name} # OS Image
        20      {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMTaskSequence -ID $SMSId).Name} # Task Sequence
        23      {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMDriverPackage -ID $SMSId).Name} # Driver Package
        19      {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMBootImage -ID $SMSId).Name} # Boot Image
        5000    {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMDeviceCollection -Id $SMSId).Name} # Device Collection
        5001    {$ObjectTypeText = $ObjectTypeName; $ObjectName = (Get-CMUserCollection -Id $SMSId).Name} # User Collection
        default {$ObjectTypeText = "unknown object type: '$($ObjectTypeName)' = $($ObjectType)"; $ObjectName = "unknown object name ($SMSId)"}
    }

    $OutputString = "$ObjectName `t[$ObjectTypeText]"
    #ContainerNodeID of 0 is the root
    While ($ContainerNodeId -ne 0)
    {
        #Find details of that container
        $ContainerNode = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServerName -Query "select * from SMS_ObjectContainerNode where ContainerNodeID = '$($ContainerNodeId)'"
        $ContainerName = ($ContainerNode).Name
        $ContainerNodeId = ($ContainerNode).ParentContainerNodeID
        $OutputString = "$ContainerName\$OutputString"
    }

    Return $OutputString
}