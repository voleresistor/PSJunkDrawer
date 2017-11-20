# Get a list of words from api.wordnik.com to create randomized usernames or passphrases
function Get-RandomWords
{
    
    param
    (
        [ValidateRange(5,250)]
        [int]
        $Limit = 10,
        
        [ValidateRange(1,9)]
        [int]
        $MinLength = 5,
        
        [ValidateRange(-1,10)]
        [int]
        $MaxLength = -1,
        
        [ValidateSet('verb','noun','adjective','conjunction','article','any')]
        [string]
        $IncludePartOfSpeech = 'any',
        
        [switch]
        $ExcludePartOfSpeech,
        
        [switch]
        $HasDictionaryDef,
        
        [string]
        $ApiKey = 'a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5'
    )
        
    # Initialize an array to store our words
    $WordList = @()
    
    ###### Build individual components of the URI ######
    # Base URI
    $baseURI = 'http://api.wordnik.com:80/v4/words.json/randomWords?'
    
    # Include parts of speech
    if ($IncludePartOfSpeech -eq 'any')
    {
        $IncludePOS = "includePartOfSpeech="
    }
    else
    {
        $IncludePOS = "includePartOfSpeech=$IncludePartOfSpeech"
    }
    
    # Exclude parts of speech
    if ($ExcludePartOfSpeech)
    {
        $ExcludePOS = "excludePartOfSpeech=family-name,given-name,proper-noun,proper-noun-plural,proper-noun-posessive,affix,suffix"
    }
    else
    {
        $ExcludePOS = 'excludePartOfSpeech='
    }
    
    # Max length of words
    $MaxWordLength = "maxLength=$MaxLength"
    
    # Min length of words
    $MinWordLength = "minLength=$MinLength"
    
    # Limit of words to return
    $WordLimit = "limit=$Limit"
    
    # Has dictionary definition
    if ($HasDictionaryDef)
    {
        $HasDictDef = 'hasDefinition=true'
    }
    else
    {
        $HasDictDef = 'hasDefinition=false'
    }
    
    # API key
    $API = "api_key=$ApiKey"
    ###### End section ######
    
    # Build our URI and get a list of random words
    $URI = "$baseURI$IncludePOS&$ExcludePoS&$MinWordLength&$MaxWordLength&$WordLimit&$HasDictDef&$API"
    $Result = Invoke-WebRequest -Uri $URI
    
    # Convert JSON result into PS object array
    $Result = $Result.Content | ConvertFrom-Json

    # Populate $WordList with words from $Result
    foreach ($word in $Result)
    {
        $WordList += $word.word
    }

    return $WordList
}

$nouns = Get-Words -PartOfSpeech noun -Limit 20
$adjectives = Get-Words -PartOfSpeech adjective -limit 10

foreach ($adj in $adjectives)
{
    Write-Host $adj -ForegroundColor Yellow -NoNewline
    Write-Host ($nouns | Get-Random) -ForegroundColor Gray
}