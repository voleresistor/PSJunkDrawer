function Get-UserResponse {
    <#
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Bool', 'String')]
        [string]$ResponseType = 'Bool'
    )

    # Just pass on through if the caller wanted a string
    if ($ResponseType -eq 'String') {
        return (Read-Host -Prompt $Prompt)
    }

    # If we need a bool we have to do more work
    $Affirmative = @('y', 'yes', 'yers')
    $Negative = @('n', 'no')
    $ValidResponse = $Affirmative + $Negative
    
    $Response = $Null
    while ($ValidResponse -notcontains $Response) {
        $Response = (Read-Host -Prompt $Prompt).ToLower()
    }

    if ($Affirmative -contains $Response) {
        return $True
    }
    else {
        return $False
    }
}