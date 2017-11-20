# Cheer up, it's Powershell!
# 08/19/2014
# Andrew Ogden
# Thanks to PowerShell.com for the cheerUp function:
# http://powershell.com/cs/blogs/tips/archive/2014/08/11/have-powershell-cheer-you-up.aspx

# ========================================
# Variables
#    Params
# ========================================
param (
    [Parameter(Mandatory=$True,Position=1)]
        [int]$max,
    [Parameter(Mandatory=$True,Position=2)]
        [int]$min,
    [Parameter(Mandatory=$True,Position=3)]
        [string]$stoptime,
    [Parameter(Mandatory=$False)]
        [switch]$help
)

# ========================================
# Variables
#    Other Variables
# ========================================
$end = ("{0:HH:mm:ss}" -f [datetime] "$stopTime")
$max = $max * 60
$min = $min * 60
$keepAlive = $true
$sleepTime = (Get-Random -Maximum $max -Minimum $min)
$count = 0
$countEnd = 0

# ========================================
# Functions
# ========================================
# Hey, cheer up, buddy!
function cheerUp {
    $text = @("You are great!", "Hero!", "What a checker you are.", "Champ, well done!", "Man, you are good!", "Guru Stuff I’d say.",
        "You are magic!", "PS> ", "Don't worry, it will all be over soon...", "Good job!", "Keep it up!")
    $message = ($text | Get-Random)
    $host.UI.RawUI.WindowTitle = Get-Location
    (New-Object -ComObject Sapi.SpVoice).Speak($message)
    Write-Host $message
}

# Sleep for random time
function justWaitin ($maxT, $minT){
    $sleepTime = (Get-Random -Maximum $maxT -Minimum $minT)
    $count = 0
    $ranTime = (Get-Random -Maximum 300 -Minimum 60)
    $countEnd = $sleepTime / $ranTime
    $timeLeft = $sleepTime
    Write-Host "Now you're gonna wait for $sleepTime seconds."

    # Periodically check the time so we don't cheer up an empty cubicle
    while ($count -lt $countend){
        Start-Sleep -Seconds $ranTime
        $count++
        $timeLeft = ($timeLeft - $ranTime)
        Write-Host "Only $timeLeft seconds left!"
        if ((Get-Date -DisplayHint Time) -gt $end){
            Write-Host "It's too late!"
            $count = $countEnd
            $keepAlive = $false
        }
    }
}

# ========================================
# Body
# ========================================

while ($keepAlive -eq $True) {
    justWaitin $max $min
    cheerUp
}