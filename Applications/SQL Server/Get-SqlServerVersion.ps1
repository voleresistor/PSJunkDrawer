function Get-SqlServerVersion
{
    param
    (
        [Parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$Property = 'SKUNAME'
    )

    # Custom object array
    $SqlVersions = @()

    foreach ($c in $ComputerName)
    {
        # Build a namespace path to the latest install
        $ManagementName = 
            (Get-WmiObject -ComputerName $c -Namespace 'root\microsoft\sqlserver' -ClassName '__NAMESPACE' -ErrorAction SilentlyContinue | 
            Where-Object {$_.Name -like 'ComputerManagement*'} | Select-Object Name | Sort-Object Name -Descending |
            Select-Object -First 1).Name

        if ($ManagementName)
        {
            $ManagementName = 'root\microsoft\sqlserver\' + $ManagementName
        }
        else
        {
            $entry = New-Object -TypeName psobject
            $entry | Add-Member -MemberType NoteProperty -Name ComputerName -Value $c
            $entry | Add-Member -MemberType NoteProperty -Name Version -Value ''
            $entry | Add-Member -MemberType NoteProperty -Name Edition -Value ''

            $SqlVersions += $entry
            Clear-Variable entry, SqlServerProperties, Version, Edition, ManagementName -ErrorAction SilentlyContinue
            continue
        }

        # Gather properties
        $SqlServerProperties = Get-WmiObject -ComputerName $c -Namespace $ManagementName -ClassName 'SqlServiceAdvancedProperty' |
            Select-Object ServiceName,PropertyName,PropertyStrValue |
            Where-Object {($_.PropertyName -eq 'VERSION') -or ($_.PropertyName -eq 'SKUNAME')}

        $Version = ($SqlServerProperties | Where-Object {$_.PropertyName -eq 'VERSION'} | Select-Object -First 1).PropertyStrValue
        $Edition = ($SqlServerProperties | Where-Object {$_.PropertyName -eq 'SKUNAME'} | Select-Object -First 1).PropertyStrValue

        $entry = New-Object -TypeName psobject
        $entry | Add-Member -MemberType NoteProperty -Name ComputerName -Value $c
        $entry | Add-Member -MemberType NoteProperty -Name Version -Value $Version
        $entry | Add-Member -MemberType NoteProperty -Name Edition -Value $Edition
        $SqlVersions += $entry

        Clear-Variable entry, SqlServerProperties, Version, Edition, ManagementName -ErrorAction SilentlyContinue
    }

    return $SqlVersions
}