#-------------------------------------------------------------------------------------------------------------
# Author: Denis Rougeau
# Date  : January 2014
#
# Purpose:  
# Query SC Orchestrator 2012 Web Service and list all runbook and Parameter GUIDs.
#
# Version:
# 1.0 - Initial Release
#
# Disclaimer: 
# This program source code is provided "AS IS" without warranty representation or condition of any kind            
# either express or implied, including but not limited to conditions or other terms of merchantability and/or            
# fitness for a particular purpose. The user assumes the entire risk as to the accuracy and the use of this            
# program code.    
#-------------------------------------------------------------------------------------------------------------
#
# Configure the following variables
$SCOWebProt      = 'http'               # Protocol
$SCOWebSvc       = 'localhost'          # Server name FQDN
$SCOWebPort      = '81'                 # Port
$UseDefaultCreds = $True                # $False, you'll be prompt for credentials
#
#-------------------------------------------------------------------------------------------------------------

function QuerySCOWebSvc 
{ Param ([string] $url) 

    $textXML = "" 

    # Get the Request XML
    $SCOrequest = [System.Net.HttpWebRequest]::Create($url)
    $SCOrequest.Method = "GET"
    $SCOrequest.UserAgent = "Microsoft ADO.NET Data Services"

    # Set the credentials to default or prompt for credentials
    if ($UseDefaultCreds -eq $true)
    { $SCOrequest.UseDefaultCredentials = $true }
    Else
      { $SCOrequest.Credentials = Get-Credential }

    # Get the response from the request
    [System.Net.HttpWebResponse] $SCOresponse = [System.Net.HttpWebResponse] $SCOrequest.GetResponse() 

    # Build the XML 
    $reader  = [IO.StreamReader] $SCOresponse.GetResponseStream()  
    $textxml = $reader.ReadToEnd()  
    [xml]$textxml = $textxml
    $reader.Close()

    Return $textxml

Trap {
        Write-Host "-> Error Querying Orchestrator Web Service."
        Return ""
     }
}

# Main
$i = 0
$colRunbooks = @()

$SCOurl = "$($SCOWebProt)://$($SCOWebSvc):$($SCOWebPort)/Orchestrator2012/Orchestrator.svc/Runbooks?`$inlinecount=allpages"
$SCOxml = QuerySCOWebSvc $SCOurl

# Get the Number of Runbooks returned
$RunbookEntries    = $SCOxml.getElementsByTagName('entry')
[int]$iNumRunbooks = $RunbookEntries.Count

# Get the number Runbooks total
[int]$iTotRunbooks = $SCOxml.GetElementsByTagName('m:count').innertext

# Process Runbooks by pages if greater the the limits the web service can return.
while ($i -lt $iTotRunbooks)
{
  $Runbookurl = "$($SCOWebProt)://$($SCOWebSvc):$($SCOWebPort)/Orchestrator2012/Orchestrator.svc/Runbooks?`$skip=" + $i.ToString()
  $Runbookxml = QuerySCOWebSvc $Runbookurl

  # Get the Runbooks returned
  $RunbookEntries = $Runbookxml.getElementsByTagName('entry')

  foreach ($Entry in $RunbookEntries) 
  {
    $RbkGUID = $Entry.GetElementsByTagName("content").childNodes.childnodes.item(0).innerText
    $RbkName = $Entry.GetElementsByTagName("content").childNodes.childnodes.item(2).innerText
    $RbkPath = $Entry.GetElementsByTagName("content").childNodes.childnodes.item(9).innerText

    $oRunbooks = New-Object System.Object
    $oRunbooks | Add-Member -type NoteProperty -name Guid  -value $RbkGUID
    $oRunbooks | Add-Member -type NoteProperty -name Name  -value $RbkName
    $oRunbooks | Add-Member -type NoteProperty -name Path  -value $RbkPath
    $oRunbooks | Add-Member -type NoteProperty -name Param -value ""

    $colRunbooks += $oRunbooks

    # Get list of Parameters for the Runbook
    $urlrunbookparam = "$($SCOWebProt)://$($SCOWebSvc):$($SCOWebPort)/Orchestrator2012/Orchestrator.svc/Runbooks(guid'$RbkGUID')/Parameters"
    $runbookxmlparam = QuerySCOWebSvc $urlrunbookparam

    # Get all the entry nodes
    $ParamEntries = $runbookxmlparam.getElementsByTagName('entry')
    foreach ($ParamEntry in $ParamEntries) 
    {
      $ParamGUID = $ParamEntry.GetElementsByTagName("content").childNodes.childnodes.item(0).innerText 
      $ParamName = $ParamEntry.GetElementsByTagName("content").childNodes.childnodes.item(2).innerText 

      $oRunbooks = New-Object System.Object
      $oRunbooks | Add-Member -type NoteProperty -name Guid  -value $ParamGUID
      $oRunbooks | Add-Member -type NoteProperty -name Name  -value $RbkName
      $oRunbooks | Add-Member -type NoteProperty -name Path  -value $RbkPath
      $oRunbooks | Add-Member -type NoteProperty -name Param -value $ParamName

      $colRunbooks += $oRunbooks

    }  # Loop ParamEntries
  } # Loop RunbookEntries
  $i += $iNumRunbooks
}

$colRunbooks | Sort-object Name, Param | Select Name,Param, GUID
Write-Host "#Runbooks returned: $iNumRunbooks"
Write-Host "#Runbooks total: $iTotRunbooks"
