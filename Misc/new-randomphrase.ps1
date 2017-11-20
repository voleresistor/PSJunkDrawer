function New-RandomPhrase
{
    <#
    .Synopsis
    Generate random phrases from 2-5 words.
    
    .Description
    Using a remote API call to wordnik.com, collect random words and use them to generate passphrases. 
    
    .Parameter WordPer
    The number of words to include in each unique object. Default: 2
    
    .Parameter Limit
    The number of unique objects to return. Default: 5
    
    .Example
    New-RandomPhrase -WordsPer 3
    
    Generate 5 objects of 3 random words each.
    #>
    param
    (
        [ValidateRange(1,5)]
        [int]
        $WordsPer = 2,
        
        [ValidateRange(1,50)]
        [int]
        $Limit = 10
    )
    # An array for our results
    $RandomResults = @()

    $AnyWord = Get-RandomWords -Limit 250 -ExcludePartOfSpeech -HasDictionaryDef
    
    $i = 1
    while ($i -le $Limit)
    {
        # Define a variable to count our word length
        $TotalLength = 0
        
        # Store results as objects and count them into word length
        $NameObj = New-Object -TypeName psobject
        $NameObj | Add-Member -MemberType NoteProperty -Name FirstWord -Value $($AnyWord | Get-Random)
        $TotalLength += ($NameObj.FirstWord).Length
        $NameObj | Add-Member -MemberType NoteProperty -Name SecondWord -Value $($AnyWord | Get-Random)
        $TotalLength += ($NameObj.SecondWord).Length
        
        # These properties only exist if greater than two words are requested
        if ($WordsPer -ge 3)
        {
            $NameObj | Add-Member -MemberType NoteProperty -Name ThirdWord -Value $($AnyWord | Get-Random)
            $TotalLength += ($NameObj.ThirdWord).Length
        }
        if ($WordsPer -ge 4)
        {
            $NameObj | Add-Member -MemberType NoteProperty -Name FourthWord -Value $($AnyWord | Get-Random)
            $TotalLength += ($NameObj.FourthWord).Length
        }
        if ($WordsPer -ge 5)
        {
            $NameObj | Add-Member -MemberType NoteProperty -Name FifthWord -Value $($AnyWord | Get-Random)
            $TotalLength += ($NameObj.FifthWord).Length
        }
        
        # Add a total count as a simple measure of complexity in a potential passphrase
        $NameObj | Add-Member -MemberType NoteProperty -Name Count -Value $TotalLength
        
        $RandomResults += $NameObj
        Clear-Variable -Name NameObj,TotalLength
        
        $i++
    }
    
    return $RandomResults
}