param (
    [string]$CsvPath,
    [string]$OutPath
)

$SubnetComment = ""
$SubnetQuery = ""

function New-Subnets ($CsvInput){
    if ($CsvInput.Network4){
        $Script:SubnetComment = "$($CsvInput.Network4), $($CsvInput.Network3), $($CsvInput.Network2), $($CsvInput.Network1)"
        $Script:SubnetQuery = "\`"%$($CsvInput.Network4)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network3)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network2)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network1)%`""
    }
    if ($CsvInput.Network3 -and !$CsvInput.Network4){
        $Script:SubnetComment = "$($CsvInput.Network3), $($CsvInput.Network2), $($CsvInput.Network1)"
        $Script:SubnetQuery = "\`"%$($CsvInput.Network3)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network2)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network1)%`""
    }
    if ($CsvInput.Network2 -and !$CsvInput.Network3){
        $Script:SubnetComment = "$($CsvInput.Network2), $($CsvInput.Network1)"
        $Script:SubnetQuery = "\`"%$($CsvInput.Network2)%`" or SMS_R_System.IPSubnets like \`"%$($CsvInput.Network1)%`""
    }
    if (!$CsvInput.Network2){
        $Script:SubnetComment = "$($CsvInput.Network1)"
        $Script:SubnetQuery = "\`"%$($CsvInput.Network1)%`""
    }
}

if (!(Test-Path $CsvPath)){
    Write-Host "CSV file not found!"
    exit
}

if (Test-Path $OutPath){
    Write-Host "Output path already exists!"
    exit
}

$CsvIn = Import-Csv -Path $CsvPath
#$CsvIn

$MofIntro =
@"
// =================================================
// Created by SubnetCollections.ps1
// Created on $(Get-Date)
// =================================================
`r`n
"@

Add-Content -Path $OutPath -Value $MofIntro

foreach ($e in $CsvIn){
    New-Subnets $e

    $CollectionEntry = 
@"
// ***** Class : SMS_Collection *****
[SecurityVerbs(-1)]
instance of SMS_Collection
{
	CollectionID = "";
	CollectionRules = {
instance of SMS_CollectionRuleQuery
{
	QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.IPSubnets like $SubnetQuery";
	QueryID = 1;
	RuleName = "$($e.Description)";
}};
	CollectionType = 2;
	CollectionVariablesCount = 0;
	Comment = "$($e.Description) - $SubnetComment";
	CurrentStatus = 0;
	HasProvisionedMember = TRUE;
	IncludeExcludeCollectionsCount = 0;
	IsBuiltIn = FALSE;
	IsReferenceCollection = FALSE;
	ISVData = NULL;
	ISVDataSize = 0;
	LastChangeTime = "20141209152029.000000+***";
	LastMemberChangeTime = "20141209152045.000000+***";
	LastRefreshTime = "20141209152649.000000+***";
	LimitToCollectionID = "SMS00001";
	LimitToCollectionName = "All Systems";
	LocalMemberCount = 85;
	MemberClassName = "";
	MemberCount = 85;
	MonitoringFlags = 0;
	Name = "$($e.Description)";
	OwnedByThisSite = TRUE;
	PowerConfigsCount = 0;
	RefreshSchedule = {
instance of SMS_ST_RecurInterval
{
	DayDuration = 0;
	DaySpan = 7;
	HourDuration = 0;
	HourSpan = 0;
	IsGMT = FALSE;
	MinuteDuration = 0;
	MinuteSpan = 0;
	StartTime = "20140109105100.000000+***";
}};
	RefreshType = 2;
	ServiceWindowsCount = 0;
};
// ***** End *****
`r`n
"@

    Add-Content -Path $OutPath -Value $CollectionEntry
}