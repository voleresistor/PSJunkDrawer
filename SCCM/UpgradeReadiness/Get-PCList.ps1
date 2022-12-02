$arrModels = @('Precision 5820 Tower X-Series','HP ProDesk 405 G1 MT','Latitude 5400','Latitude 5420','Latitude 5424 Rugged','Latitude 5430','Latitude 5480','Latitude 5490','Latitude 7389','Latitude 7390 2-in-1','Latitude 7400','Latitude 7414','Latitude 7480','Latitude 7490','OptiPlex 3050','OptiPlex 3060','OptiPlex 3070','OptiPlex 7450 AIO','Precision 3571','Precision 7720','Precision 7730','Precision 7740','Precision T1700','Precision Tower 3420','Precision Tower 3620','Surface Pro','Surface Pro 6')
$allWks = Get-CMDevice -CollectionName "All Workstations" -Fast | Select-Object -Property Name,ResourceId
$SCCMserver = "bry-cm-0001.puffer.com"
$SCCMnameSpace = "root\SMS\site_PUF"
$arrResults = @()

foreach ($objComputer in $allWks) {
	$qry = "Select Model from SMS_G_System_Computer_System where ResourceID = '$($objComputer.ResourceId)'"
	$strModel = (Get-CimInstance -ComputerName $SCCMserver -Namespace $SCCMnameSpace -Query $qry).Model
	
	$objModelData = [PSCustomObject]@{
		ComputerName = "$($objComputer.Name)"
		ResourceId = "$($objComputer.ResourceId)"
		Model = "$strModel"
	}
	
	$arrResults += $objModelData
}

$arrAnalytics = @()
foreach ($strModel in $arrModels) {
	$idx = -1
	$arrThismodel = $arrResults | Where-Object { $_.Model -eq $strModel }
	if ($arrThismodel.Count -ge 3) {
		for ($i = 2; $i -gt 0; $i--) {
			$lastIdx = $idx
			while ($idx -eq $lastIdx) {
				$idx = $(Get-Random -Maximum ($($arrThismodel.Count) - 1) -Minimum 0)
			}
			$arrAnalytics += $arrThismodel[$idx]
		}
	}
	else {
		foreach ($objModel in $arrThismodel) {
			$arrAnalytics +=$objModel
		}
	}
}