#region Get-MemoryStats
Function Get-MemoryStats
{
    <#
    .Synopsis
    Displays information about memory usage on local and remote computers
    
    .Description
    Collect and display information such as free, used, and total memory. Additionally
    displays free and used memory as a percent of total.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-MemoryStats
    
    Get data from the local computer
    
    .Example
    Get-MemoryStats -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    #>
    param
    (
        # Take an array as input so we can pipe a list of computers in
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ComputerName = $env:computername
    )

    begin
    {
        # Create an array to hold our objects
        $AllMembers = @()
    }
    
    process
    {
        # Loop through each object in the input array
        foreach ($target in $ComputerName)
        {
            # Get relevant memory info from WMI on the target computer
            $MemorySpecs = Get-WmiObject -Class Win32_Operatingsystem -ComputerName $target -ErrorAction SilentlyContinue | Select-Object FreePhysicalMemory,TotalVisibleMemorySize
                
            # Check that we got a result from the WMI query and skip this computer if not
            #if (! $MemorySpecs)
            #{
            #    continue
            #}
            
            # Create some variables using the data from the WMI query
            $FreeMemory                 = $MemorySpecs.FreePhysicalMemory
            $TotalMemory                = $MemorySpecs.TotalVisibleMemorySize
            $UsedMemory                 = $TotalMemory - $FreeMemory
            
            if ($FreeMemory -eq $null)
            {
                $FreeMemoryPercent = 0
                $UsedMemoryPercent = 0
            }
            else
            {
                $FreeMemoryPercent   = "{0:N2}" -f (($FreeMemory / $TotalMemory) * 100)
                $UsedMemoryPercent   = "{0:N2}" -f (100 - $FreeMemoryPercent)
            }
            
            $FreeMemory            = "{0:N2}" -f ($FreeMemory / 1mb)
            $TotalMemory           = "{0:N2}" -f ($TotalMemory / 1mb)
            $UsedMemory            = "{0:N2}" -f ($UsedMemory / 1mb)
            
            # Create and populate an object for the data
            $FreeAndTotal = New-Object -TypeName PSObject
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name ComputerName -Value $target
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name TotalMemoryGB -Value $TotalMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemoryGB -Value $FreeMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemoryGB -Value $UsedMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemoryPercent -Value $FreeMemoryPercent
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemoryPercent -Value $UsedMemoryPercent

            # Add object to the collection array
            $AllMembers += $FreeAndTotal
            
            Clear-Variable FreeMemory,TotalMemory,UsedMemory,FreeMemoryPercent,UsedMemoryPercent,MemorySpecs
        }
    }
    
    end
    {    
        # Return the collection array
        Return $AllMembers
    }
}
<#    
    Example Output:
    
    PS C:\> Get-MemoryStats -ComputerName $(Get-ADComputer -Filter {enabled -eq 'True'}).Name | ft
    ComputerName TotalMemory FreeMemory UsedMemory FreeMemoryPercent UsedMemoryPercent
    ------------ ----------- ---------- ---------- ----------------- -----------------
    RIGEL                839        359        480             42.76             57.24
    SOL                 1871        865       1006             46.23             53.77
    APODIS               971        332        639             34.17             65.83
    VYCANIS            12279       5294       6985             43.11             56.89
    SADATONI             509        300        209             58.89             41.11
    DENEB               2777        765       2012             27.54             72.46
    RANA                 512        337        175             65.85             34.15
    POLONIUM           32709      25027       7682             76.51             23.49
#>
#endregion