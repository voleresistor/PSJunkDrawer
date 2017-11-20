#region New-Password
function New-Password
{
    <#
    .Synopsis
    Generate a random password.
    
    .Description
    Generate a random password. Length defaults to 16 characters. Special characters, numbers, and capital
    letters can be removed using switches. Double characters are not accepted.
    
    .Parameter PasswordLength
    The number of characters to select for the password.
    
    .Parameter NoSpecialChars
    Disable the use of special characters in the password.
    
    .Parameter NoCaps
    Disable the use of capital letters in the password.
    
    .Parameter NoNumbers
    Disable the use of numbers in the password.
    
    .Parameter EnableDebug
    Enable additional output about the password building process.
    
    .Parameter NumericPin
    Output a purely numeric PIN.
    
    .Parameter PinLength
    The number of digits to select for the PIN. Length defaults to 4 characters.
    
    .Example
    New-Password
    
    Get a 16 character password including at least 1 of each of the following:
        - Numbers
        - Upper case letters
        - Lower case letters
        - Special characters
    
    .Example
    New-Password -NoSpecialChars
    
    Get a 16 character password without special characters.
    
    .Example
    New-Password -PasswordLength 24
    
    Get a 24 character password including at least 1 of each of the following:
        - Numbers
        - Upper case letters
        - Lower case letters
        - Special characters
        
    .Example
    New-Password -NumericPin
    
    Get a 4 digit PIN consisting of only numerals.
    
    .Example
    New-Password -EnableDebug
    
    Get a 16 character password with verbose output about script actions.
    #>
    [cmdletbinding(DefaultParameterSetName='Password')]
    
    param
    (
        [Parameter(Mandatory=$false,Position=0,ParameterSetName='Password')]
        [int]$PasswordLength = 16,
        
        [Parameter(Mandatory=$false,ParameterSetName='Password')]
        [switch]$NoSpecialChars,
        
        [Parameter(Mandatory=$false,ParameterSetName='Password')]
        [switch]$NoCaps,
        
        [Parameter(Mandatory=$false,ParameterSetName='Password')]
        [switch]$NoNumbers,
        
        [Parameter(Mandatory=$false,ParameterSetName='NumericPin')]
        [int]$PinLength = 4,
        
        [Parameter(Mandatory=$false,ParameterSetName='NumericPin')]
        [switch]$NumericPin,
        
        [Parameter(Mandatory=$false)]
        [switch]$EnableDebug
    )
    
    # Configure debug preferences
    if ($EnableDebug)
    {
        $oldDebugPreference = $DebugPreference
        $DebugPreference = 'Continue'
    }
    
    # Define charsets
    $lowerChars = 'abcdefghijklmnopqrstuvwxyz' * 55
    $capitalChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' * 55
    $specialChars = '`~!@#$%^&*-+_=|:;<>,.?' * 65
    $numChars = '1234567890' * 143
    
    # Define match strings
    $lowerMatch = '.*[a-z]{1,}.*'
    $capitalMatch = '.*[A-Z]{1,}.*'
    $specialMatch = '.*[`~!@#$%^&*\-+_=|:;<>,.?]{1,}.*'
    $numMatch = '.*[0-9]{1,}.*'
    
    # Store password
    $passwdString = $null
    
    # Adjust settings based on PIN or password selection
    if ($NumericPin)
    {
        Write-Debug 'Enabling only numerals for numeric PIN'
        $pwdChars = $numChars
        
        Write-Debug 'Setting length to $PinLength'
        $Length = $PinLength
    }
    else
    {
        Write-Debug 'Setting length to $PasswordLength'
        $Length = $PasswordLength
        
        Write-Debug 'Adding lower case letters to potential password characters.'
        $pwdChars = $lowerChars
        
        if (!($NoCaps))
        {
            Write-Debug 'Adding upper case letters to potential password characters.'
            $pwdChars += $capitalChars
        }
        
        if (!($NoSpecialChars))
        {
            Write-Debug 'Adding special characters to potential password characters.'
            $pwdChars += $specialChars
        }
        
        if (!($NoNumbers))
        {
            Write-Debug 'Adding numerals to potential password characters.'
            $pwdChars += $numChars
        }
    }
    
    # Convert password character string to an array
    Write-Debug 'Convert password character string to an array.'
    $pwdChars = ($pwdChars.ToCharArray())
    
    # Wrap code in try block to enable control of expections and closing events
    try
    {
        Write-Debug 'Begin building password.'
        # Create and check new passwords until match is valid
        while ($validPassword -ne $true)
        {
            # Initialize some variables for program use
            $nextChar = $null
            $lastChar = $null
            $validPassword = $true
        
            while ($passwdString.Length -lt $Length)
            {
                $lastChar = $nextChar
                $nextChar = Get-Random -InputObject $pwdChars
                Write-Debug "Last Char: $lastChar"
                Write-Debug "Next Char: $nextChar"
            
                if ($nextChar -ne $lastChar)
                {
                    Write-Debug 'New character does not match previous. Adding to password string.'
                    $passwdString += $nextChar
                }
                else
                {
                    Write-Debug 'New character matches previous. Trying again.'
                }
                
                if ($EnableDebug)
                {

                    Write-Debug "Current Password String: $passwdString`r`n"
                    Write-Debug "Password String Length: $($passwdString.Length)"
                }
            }
            
            if ($NumericPin)
            {
                # Verify that password string only contains numbers
                Write-Debug 'Configuring regex match for NumericPIn only.'
                $numMatch = '^' + ($numMatch -replace ('\.\*','')) + '$'
                if (!($passwdString) -match $numMatch)
                {
                    Write-Debug 'Found a non-numeric character in numeric only PIN. Exiting.'
                    exit 5
                }
                else
                {
                    Write-Debug 'Numeric PIN successfully matched.'
                }
            }
            else
            {
                Write-Debug 'Checking for required characters in password string.'
                
                # Check that at least one lower case letter exists
                if (!($passwdString -cmatch $lowerMatch))
                {
                    Write-Debug 'Required lower case not found. Will build new password.'
                    $validPassword = $false
                }
                else
                {
                    Write-Debug 'Found required lower case.'
                }
                
                # Check that at least one capital letter exists if necessary
                if (!($NoCaps) -and !($passwdString -cmatch $capitalMatch))
                {
                    Write-Debug 'Required capital not found. Will build new password.'
                    $validPassword = $false
                }
                else
                {
                    Write-Debug 'Found required capital.'
                }
                
                # Check that at least one number exists if necessary
                if (!($NoNumbers) -and !($passwdString -match $numMatch))
                {
                    Write-Debug 'Required number not found. Will build new password.'
                    $validPassword = $false
                }
                else
                {
                    Write-Debug 'Found required number.'
                }
                
                # Check that at least one special character exists if necessary
                if (!($NoSpecialChars) -and !($passwdString -match $specialMatch))
                {
                    Write-Debug 'Required special character not found. Will build new password.'
                    $validPassword = $false
                }
                else
                {
                    Write-Debug 'Found required special character.'
                }
            }
        }
        
        Write-Debug "Returning successfully built password string: $passwdString"
        return $passwdString
    }
    # Always do this, regardless of outcome
    finally
    {
        $DebugPreference = $oldDebugPreference
    }
}
<#
Expected output:

    PS C:\temp> New-Password
    27j>:9$2%18t!w^F
    PS C:\temp> New-Password -NoSpecialChars
    32ondK8E2W0VtLg4
    PS C:\temp> New-Password -PasswordLength 20
    i3X%,C,S<d+LjQWXDK9k
    
#>
#endregion