param(
    [switch]$IncludeMessage,
    [switch]$ShowLogs,
    [array]$ComputerList = @("HOUDFS02.dxpe.com","HOUDFS03.dxpe.com","OMADFS01.dxpe.com","AKPDFS01.dxpe.com","AKPDFS02.dxpe.com","CGYDFS01.dxpe.com","CINDFS02.dxpe.com","EDMDFS01.dxpe.com","GDNDFS02.dxpe.com","GOLDENDFS01.dxpe.com","MTSDFS01.dxpe.com","PMIDFS02.dxpe.com")
)

function Get-ReplicationErrors ($sComputerName){
    $fEventLogs = Invoke-Command -ComputerName $sComputerName -ScriptBlock { Get-EventLog -LogName "DFS Replication" -After ((Get-Date).AddDays(-7)) | ?{ ($_.eventID -eq 4304) -or ($_.eventID -eq 4302)} } -ErrorAction SilentlyContinue
    Return $fEventLogs
}

function Write-LogOutput ($sLogs){
    if ($IncludeMessage){
        $sLogs | select TimeWritten,EventId,Message | Format-Table
    } else {
        $sLogs | select TimeWritten,EventId | Format-Table
    }
}

function main (){
    foreach ($server in $Computerlist){
        
        $mEventLogs = Get-ReplicationErrors -sComputerName $server
        Write-Host "===== $server ($($mEventLogs.Count))=====" -ForegroundColor Cyan
        if ($ShowLogs){
            Write-LogOutput -sLogs $mEventLogs
        }
        
        Clear-Variable mEventLogs
    }
}

main