####################
function New-ObjectWithAddPropertyScriptMethod
####################
{     
    <#
    .synopsis
    Return a PSObject with AddProperty ScriptMethod
    
    .description
    Return a PSObject with AddProperty ScriptMethod that takes two positional arguments, Name and Value.

    .example
    $object = New-ObjectWithAddPropertyScriptMethod;
    $object.AddProperty('username', 'johndoe');
       
    #>

    $record = New-Object -TypeName PSObject;

    Add-Member -Name AddProperty -InputObject $record -MemberType ScriptMethod -Value {
        if ($args.Count -eq 2)
        {
            ($name, $value) = $args;

            if (Get-Member -InputObject $this -Name $name)
            {
                $this.$name = $value;

            } # if (Get-Member -InputObject $this -Name $name)
            else
            {
                Add-Member -InputObject $this -MemberType NoteProperty -Name $name -Value $value;

            } # if (Get-Member -InputObject $this -Name $name)  ... else
                                    
        } # if ($args.Count -eq 2)

    } # Add-Member -Name AddProperty ...

    $record;

} # function New-ObjectWithAddPropertyScriptMethod

####################
function Get-NslookupSrvRecord
####################
{
    <#
    .synopsis
    Get SRV record for specified FQDN(s)

    .description
    PowerShell lacks a way to return SRV records because .NET lacks a way to return SRV records.
    Does not return any data, warning, or errror if no SRV record found.  
    
    .oputputs
    PSObject with properties
    
    - FQDN: FQDN specified, which is the first line returned that does not begin with whitespace.
    
    - Text: Array of any lines returned that do not begin with whitespace after the first one.  Can be empty array.

    - Other properties vary with the SRV record.  Any line beginning with whitepsace is split into name/value pairs over the ' = ' delimiter.
    
    .parameter FQDN
    Specified FQDN(s) for which to attempt to return SRV records

    .example
    Get-NslookupSrvRecord mail.microsoft.com

    #>

    param( 
        [parameter(ValueFromPipeline=$true)][string[]]$FQDN
    );
    
    begin
    {
        $ErrorActionPreference = 'SilentlyContinue';

    } # begin

    process
    {
        foreach ($_fqdn in $FQDN)
        {
            $cmd = "set type=srv`n$fqdn";
            Write-Verbose "$($MyInvocation.MyCommand.Name) -FQDN $_fqdn"; 

            $record = $null;
            $data = @()

            $cmd | nslookup.exe 2>&1 |
            ? {
                $_ -and
                $_ -notmatch '^Address:' -and
                $_ -notmatch '^Server:' -and
                $_ -notmatch '^Default Server:' -and
                $_ -notmatch '^>'
            } |
            % {
                Write-Debug $_;
                switch -Regex ($_)
                {
                    "^[^\s]"
                    {
                        if ($record)
                        {
                            $data += $_;
                            
                        } # if ($record)
                        else
                        {
                            $record = New-ObjectWithAddPropertyScriptMethod;
                            $record.AddProperty('FQDN', ($_ -replace '\s.*'));

                        } # if ($record) ... else

                    } # "[^\s]"

                    "^\s"
                    {
                        if ($_ -match ' = ')
                        {
                            $name = $_ -replace '^\s*' -replace '\s.* = .*';
                            $value = $_ -replace '.* = ' -replace '\s*$';
                            $record.AddProperty($name, $value);

                        } # if ($_ -match '\s')
                        else
                        {
                            $data += $_;

                        } # if ($_ -match '\s')

                    } # " = "

                } # switch -Regex ($_)

            } # $cmd | nslookup.exe

            $record.AddProperty('Text', $data);

            $record;

        } # foreach ($_fqdn in $FQDN)

    } # process

} # function Get-NslookupSrvRecord