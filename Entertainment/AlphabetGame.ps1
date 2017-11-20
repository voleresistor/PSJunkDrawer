function evaluateResponse(){
    $answer = 'abcdefghijklmnopqrstuvwxyz'
    if ($answer -eq (Read-Host -Prompt 'Enter the letters of the alphabet')){
        Write-Host 'Congratulations! You entered the alphabet correctly!'
    } else {
        Write-Host 'Whoops! You entered the alphabet incorrectly!'
    }
}

function main(){
    showTitle
    evaluateResponse
    gameOver
}

function gameOver(){
    if ((Read-Host -Prompt 'Would you like to play agaain? (yes or no)') -match '[y|Y|yes|Yes|YES]'){
        main
    } else {
        break
    }
}

function showTitle(){
    Write-Host "`r`nThe Alphabet Game!`r`n..........by Papa!`r`n"
}

Clear-Host
main