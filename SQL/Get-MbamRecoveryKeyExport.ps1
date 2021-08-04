function Get-MbamRecoveryKeyExport {
    [CmdletBinding()]
    param (
        [Alias('s','Server','ServerName')]
        [Parameter(Mandatory=$true,
            Position=1,
            HelpMessage="The name of the SQL server hosting the MBAM data.")]
        [string]$ComputerName,

        [Alias('i','Instance')]
        [Parameter(Mandatory=$false,
            Position=2,
            HelpMessage="The SQL instance name. Do not define to use the default instance.")]
        [string]$SqlInstance = "",

        [Alias('File','Output')]
        [Parameter(Mandatory=$false,
            Position=3,
            HelpMessage="Path in which to save the output data. Do not define to use current path.")]
        [string]$OutPath = $((Get-Location).Path),

        [Alias('r','Rows')]
        [Parameter(Mandatory=$false,
            Position=4,
            HelpMessage="Maximum number of rows to query from the database.")]
        [int]$MaxRows = 10000
    )

    # Generate a file name
    $fileName = $(Get-Date -UFormat "%Y_%m_%d") + "_MBAMKeys.csv"
    $FullPath = $OutPath + '\' + $fileName

    # Define SQL Query
    $sqlQuery = @"
    SELECT TOP ($($MaxRows.ToString())) [VolumeId]
        ,[LastUpdateTime]
        ,[RecoveryKeyId]
        ,RecoveryAndHardwareCore.DecryptString([RecoveryKey], DEFAULT) as 'RecoveryKey'
        ,[Disclosed]
    FROM [CM_PUF].[dbo].[RecoveryAndHardwareCore_Keys]
"@

    # Create the SQL connection
    if ($SqlInstance -ne "") {
        $SqlInstance = "\" + $SqlInstance
    }
    $ServerInstance = "${ComputerName}$SqlInstance"
    $Database = "CM_PUF"
    $ConnectionString = "Server=$ServerInstance; Database=$Database; Integrated Security=True"

    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $sqlConnection.Open()
    }
    catch {
        Write-Error $_.Exception.Message
        Write-Warning "Cannot make the SQL connection!"
        return
    }

    # Run the query
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $sqlQuery
    $sqlCmd.Connection = $sqlConnection

    $reader = $sqlCmd.ExecuteReader()

    $dataTable = New-Object System.Data.DataTable
    $dataTable.Load($reader)

    $sqlConnection.Close()

    # Create the file
    $($dataTable | Select-Object -Property VolumeId,LastUpdateTime,RecoveryKeyId,RecoveryKey,Disclosed) |
    Export-Csv -Delimiter ',' -NoTypeInformation -Path $FullPath -Encoding "UTF8"

    Write-OutPut $FullPath
}