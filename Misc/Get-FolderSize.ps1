function Get-FolderSize
{
    <#
    .Synopsis
    Gather total size of folders.
    
    .Description
    Recursively get total size of all files inside every folder path given. Limited by access
    permissions of running user. 
    
    .Parameter FolderPath
    A name, array, or comma-separated list of folder paths to calculate the size of.
    
    .Example
    Get-FolderSize
    
    Get total size of all files inside current path.
    
    .Example
    Get-FolderSize -Path c:\temp
    
    Get total size of all files into c:\temp
    
    .Example
    (ls c:\ -Attributes D).FullName | Get-FolderSize
    
    Get total size of all files within each folder returned by (ls c:\ -Attributes D)
    #>
    param
    (
        [parameter(
            ValueFromPipeline=$true
        )]
        [string[]]$FolderPath = $(Get-Location).Path # The path to be measured
    )

    begin
    {
        # Create an array to store our pipeline object results
        $AllMembers = @()
    }

    process
    {
        # Create a float to store our file size total in bytes
        [float]$totalSize   = 0
        
        # Iterate through the array of paths submitted
        foreach ($path in $FolderPath)
        {
            # Get every file in the target path
            ForEach ($file in (Get-ChildItem $path -Recurse -Attributes !D))
            {
                # Use measure object to get the byte size of each file and add
                # it to $totalSize
                $fileSize = Measure-Object -InputObject $file -Property length -Sum
                $totalSize += $fileSize.sum
            }
        }
        
        # Create and populate our custom object
        # TODO: Do we need to collect size three different ways? Maybe we can customize the object
        # based on input from user and just default to GB if not specified.
        $PathSum = New-Object -TypeName PSObject
        $PathSum | Add-Member -MemberType NoteProperty -Name Path -Value $path
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInGB -Value ("{0:N2}" -f ($totalSize / 1GB))
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInMB -Value ("{0:N2}" -f ($totalSize / 1MB))
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInKB -Value ("{0:N2}" -f ($totalSize / 1KB))
        
        # Add custom object to array
        $AllMembers += $PathSum
    }
        
    end
    {
        # Ship that shit back to the user
        return $AllMembers
    }
}