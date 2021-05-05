function Get-FormattedTimeSpan
{
    <#
    .Synopsis
    Return a string formatted in HH:MM:SS.mmm
    
    .Description
    Take a starting DateTime object and return a formatted string of the time bewteen then and now.

    .Parameter StartDate
    A datetime compatible string specifying the start time.
    
    .Example
    Get-FormattedTimeSpan -StartDate "01/01/2020"
    
    Get the time since Jan 1, 2020.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [DateTime]$StartDate
    )

    $Now = (Get-Date)
    $TimeSpan = New-TimeSpan -Start $StartDate -End $Now

    return "$(($TimeSpan.Hours).ToString().Padleft(2,"0")):$(($TimeSpan.Minutes).ToString().Padleft(2,"0")):$(($TimeSpan.Seconds).ToString().Padleft(2,"0")).$(($TimeSpan.Milliseconds).ToString().Padleft(3,"0"))"
}

function Get-DeprecatedTlsSenders
{
    <#
    .Synopsis
    Gather data on the sources of emails sent using deprecated TLS versions.
    
    .Description
    Senders using TLS 1.0/1.1 pose a potential security risk. To locate them, this function queries Exchange Online to find messages that came in using a deprecated version of TLS and reports the sender, source IP, TLS version, and time sent.
    
    .Parameter EndDate
    A datetime compatible string specifying the end of the date range.

    .Parameter StartDate
    A datetime compatible string specifying the start of the date range.
    
    .Example
    Get-DeprecatedTlsSenders
    
    Get data on deprecated TLS senders.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$false)]
        [DateTime]$StartDate = ((Get-Date).AddDays(-1)),

        [Parameter(Mandatory=$false)]
        [DateTime]$EndDate = (Get-Date),

        [Parameter(Mandatory=$false)]
        [string]$ReportPath = 'C:\temp\TLSReports',

        [Parameter(DontShow)]
        [int]$PageSize = 5000,

        [Parameter(DontShow)]
        [int]$MaxPages = 1000000 / $PageSize,

        [Parameter(DontShow)]
        [Regex]$TlsVerRegex = [Regex]::new("(?<=tlsversion=)(.*)(?=;)")
    )

    # Change the EAP for this session
    $ErrorActionPreference = 'SilentlyContinue'

    # Verify that the ExchangeOnline module is available and import it
    If (Get-Module -ListAvailable -Name ExchangeOnlineManagement)
    {
        Import-Module -Name ExchangeOnlineManagement
    }
    else
    {
        Write-Warning -Message "ExchangeOnlineManagement module required but not found."
        return $null
    }

    # Gather credential and connect to ExchangeOnline using modern authentication
    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName

    # TESTING Verify that the connection was successful
    if (Get-Command -Name Get-Mailbox )
    {
        Write-Host "Successfully connected to Exchange Online."
    }
    else
    {
        Write-Warning -Message "Not connected to Exchange Online. Something went wrong."
        return $null
    }

    # Gather the requested message trace data
    $PageNum = 1

    $ThisPage = Get-MessageTrace -Page $PageNum -PageSize $PageSize -EndDate $EndDate -StartDate $StartDate
    while (($ThisPage -ne $null) -and ($PageNum -le $MaxPages))
    {
        # Store relevant results
        $TraceResults += $ThisPage | Where-Object { $_.SenderAddress -like "*puffer*" } | Select-Object SenderAddress,RecipientAddress,MessageTraceID,FromIP
        Write-Progress -Activity "Gathering message traces from $StartDate to $EndDate" -Status "Getting page $PageNum..." -CurrentOperation "$($TraceResults.Count) results found"

        # Increment and gather more
        $PageNum++
        Clear-Variable -Name ThisPage
        $ThisPage = Get-MessageTrace -Page $PageNum -PageSize $PageSize -EndDate $EndDate -StartDate $StartDate
    }

    #$TraceResults.Count

    # Get history details for the original reception of the sent message where TLS 1.0/1.1 was used
    $CollectedTraces = @()

    $DetailStart = (Get-Date)
    for ($i = 0; $i -lt $($TraceResults.Count); $i++)
    {
        Write-Progress -Activity "Analyzing message $i of $($TraceResults.Count)" -Status "Analyzing $($TraceResults[$i].MessageTraceId)" -CurrentOperation "$($CollectedTraces.Count) results found in $(Get-FormattedTimeSpan -StartDate $DetailStart)" -PercentComplete (($i / $TraceResults.Count) * 100)
        $RawTrace = (Get-MessageTraceDetail -MessageTraceId $($TraceResults[$i].MessageTraceId) -RecipientAddress $($TraceResults[$i].RecipientAddress) -Event 'Receive').Data
        if ($RawTrace -ne $null)
        {
            $TlsVerStr = ($RawTrace -split(':') | Select-String 'tlsversion').ToString()
            $TlsVer = $TlsVerRegex.Match($TlsVerStr)
            if (($TlsVer.Success) -and ($tlsVer.Value -notlike "*TLS1_2*") -and ($tlsVer.Value -ne "NONE"))
            {
                $Props = @{
                    TLSVersion = $TlsVer.Value;
                    SenderAddress = $TraceResults[$i].SenderAddress;
                    RecipientAddress = $TraceResults[$i].RecipientAddress;
                    FromIp = $TraceResults[$i].FromIP;
                    ReceiveDate = $TraceResults[$i].Received;
                    MessageId = $TraceResults[$i].MessageId;
                    MessageTraceId = $TraceResults[$i].MessageTraceId
                }
                $DeprecatedRecord = New-Object -TypeName PSObject -Property $Props

                $CollectedTraces += $DeprecatedRecord
                $DeprecatedRecord
                Clear-Variable DeprecatedRecord
            }
        }

        Clear-Variable -Name RawTrace
    }

    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false

    # Only act if we had any results
    if ($CollectedTraces.Count -ge 1)
    {
        # Create $ReportPath and report
        New-Item -Path $ReportPath -ItemType 'Directory'  | Out-Null
        if (!(Test-Path -Path $ReportPath ))
        {
            Write-Warning -Message "Couldn't create report folder $ReportPath."
        }
        else
        {
            $DateName = "$(Get-Date -Uformat "%Y-%m-%d").csv"
            $CollectedTraces | Export-Csv -Path "$ReportPath\$DateName" -Delimiter ',' -NoTypeInformation
        }

        # Return data to console
        return $CollectedTraces
    }
    else
    {
        Write-Warning -Message "No results found."
    }
}