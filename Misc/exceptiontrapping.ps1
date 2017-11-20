Function Test-Trap() {
    trap [Exception] {
        Write-Host
        #Write-Error $("TRAPPED: " + $_.Exception.GetType().FullName);
        Write-Error $("TRAPPED: " + $_.Exception.Message);
        continue;
    }
    Write-Host "Hello " -NoNewline;
    throw (New-Object IO.DirectoryNotFoundException);
    Write-Host "World!";
    Write-host "Hello World!";
}

Function Test-Trap2() {
    trap [Exception] {
        Write-Host "Trapped $($_.Exception.Message) in the Outer Trap!"
        Continue
    }

    if($true) { # a nested scope
        trap [Exception] {
            Write-Host "Trapped $($_.Exception.Message) in the Inner Trap!"
            Break
        }
        Throw "some fun";
        "We won't reach this!"
    }
    "Wasn't that fun?"
}

Function Test-Trap3([switch]$CauseProblems){
    $result = $true
    if($CauseProblems){
        "Try to create a folder, but it's parent doesn't exist, so throw:"
        throw (new-object IO.DirectoryNotFoundException)
    }
    else {
        "Created a folder, now fake a problem creating a file."
        throw "Couldn't create a file"
        # You'd see this if continue returned into this scope
        "Created the file with no problems."
    }

    "Returning the result..." # Ought to be false, but won't be
    return $result

    trap [IO.DirectoryNotFoundException] {
        write-host "Can't find that directory!"
        $result = $false
        break
    }

    trap {
        write-host "`$Result started to set $result."
        write-host $("`tTRAPPED: " + $_.Exception.GetType().FullName)
        write-host $("`tTRAPPED: " + $_.Exception.Message)$result = $false
        write-host "`$Result is now set to $result, since you had a problem."
        continue
    }
}

Test-Trap3 -CauseProblems