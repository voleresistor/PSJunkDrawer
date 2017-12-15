function Get-CsvColumnData
{
    <#
    .SYNOPSIS
    Get values and frequency of values for all columns in a CSV file.
    
    .DESCRIPTION
    Long description
    
    .PARAMETER FileName
    Name of the file to parse.

    .PARAMETER Delimiter
    The delimiter between cells in the CSV file.
    
    .PARAMETER ColumnName
    Specific column to gather.
    
    .EXAMPLE
    Get-CsvColumnData -FileName c:\temp\test.csv

    Get data for all columns in c:\temp\test.csv.
    
    .NOTES
    General notes
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({Test-Path -Path $_ -Type Leaf})]
        [string]$FileName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$Delimiter,

        [Paramter(Mandatory=$false, Position=3)]
        [String]$ColumnName
    )

    begin
    {
        $csv = Import-Csv -Path $FileName -Delimiter $Delimiter

        if (!($ColumnName))
        {
            $ColumnNames = Get-CsvColumnNames -FileName $FileName -Delimiter $Delimiter
        }
    }
    process
    {

    }
    end
    {

    }
}