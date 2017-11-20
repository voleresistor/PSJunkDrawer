 #requires -Version 3
function Get-LoggedOnUser{
    param(
        $ComputerName,
        $Credential
    )

    Get-WmiObject -Class Win32_ComputerSystem @PSBoundParameters |
    Select-Object -ExpandProperty UserName
}

function Get-LoggedOnUserSession
{
    param
    (
        $ComputerName,
        $Credential
    )
 
    Get-WmiObject -Class Win32_LogonSession @PSBoundParameters |
    ForEach-Object {
        $_.GetRelated('Win32_UserAccount') |
        Select-Object -ExpandProperty Caption
    } |
    Sort-Object -Unique
}

function Test-Port
{
    Param([string]$ComputerName,$port = 5985,$timeout = 1000)
 
    try
    {
        $tcpclient = New-Object -TypeName system.Net.Sockets.TcpClient
        $iar = $tcpclient.BeginConnect($ComputerName,$port,$null,$null)
        $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
        if(!$wait)
        {
            $tcpclient.Close()
            return $false
        }
        else
        {
            # Close the connection and report the error if there is one
           
            $null = $tcpclient.EndConnect($iar)
            $tcpclient.Close()
            return $true
        }
    }
    catch
    {
        $false
    }
}

# Get airports for a country
 
function Get-Airport
{
    param($Country, $City='*')
 
    $webservice = New-WebServiceProxy -Uri 'http://www.webservicex.net/globalweather.asmx?WSDL'
    $data = [xml]$webservice.GetCitiesByCountry($Country)
    $data.NewDataSet.Table |
      Where-Object { $_.City -like "*$City*" }
 
}

#Get weather from a local airport
 
function Get-Weather
{
    param($City, $Country='Germany')
 
    $webservice = New-WebServiceProxy -Uri 'http://www.webservicex.net/globalweather.asmx?WSDL'
    $data = [xml]$webservice.GetWeather($City, $Country)
    $data.CurrentWeather
}

function ConvertTo-NeutralString ($Text)
{
  $changes = New-Object System.Collections.Hashtable
  $changes.ß = 'ss'
  $changes.Ä = 'Ae'
  $changes.ä = 'ae'
  $changes.Ü = 'Ue'
  $changes.ü = 'ue'
  $changes.Ö = 'Oe'
  $changes.ö = 'oe'
  $changes.' ' = '_'
  
  Foreach ($key in $changes.Keys)
  {
    $text = $text.Replace($key, $changes.$key)
  }
 
  $text
}