function Monitor-BitsTransfer
{
    param
    (
        [string]$JobId
    )

    # Run as long as the transfer is active
    while ((Get-BitsTransfer -JobId $JobId).JobState -eq 'Transferring')
    {
        # Gather job info and calculate percent complete
        $trans = Get-BitsTransfer -JobId $JobId
        $pctComplete = $(($trans.BytesTransferred / $trans.BytesTotal) * 100)

        # Display progress and rest for a moment
        Write-Progress -Activity "$($trans.TransferType): $($trans.DisplayName) [$([math]::round($pctComplete, 2))% Complete]" -Status "Status: $($trans.JobState)" -PercentComplete $pctComplete
        Start-Sleep -Seconds 1
    }

    # Exit with final status
    $trans = Get-BitsTransfer -JobId $JobId
    return "Result: $($trans.JobState)`r`nErrors: $($trans.ErrorCondition)"
}