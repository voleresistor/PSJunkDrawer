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