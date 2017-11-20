# x64 definitions
#####################################

# Antivirus definitions
#$AntiVirusSource = 'http://go.microsoft.com/fwlink/?LinkID=121721&arch=x64'
#$AntiVirusFile = '\\housccm03.dxpe.com\ScepUpdates\x64\mpam-fe.exe'

# Antispyware definitions
#$AntiSpywareSource = 'http://go.microsoft.com/fwlink/?LinkId=211054'
#$AntiSpywareFile = '\\housccm03.dxpe.com\ScepUpdates\x64\mpam-d.exe'

# Antimalwae definitions
#$AntiMalwareSource = 'http://go.microsoft.com/fwlink/?LinkId=197094'
#$antiMalwareFile = '\\housccm03.dxpe.com\ScepUpdates\x64\nis_full.exe'

# Download fresh definitions
#Invoke-WebRequest -Uri $AntiVirusSource -OutFile $AntiVirusFile
#Invoke-WebRequest -Uri $AntiSpywareSource -OutFile $AntiSpywareFile
#Invoke-WebRequest -Uri $AntiMalwareSource -OutFile $antiMalwareFile

# Old script
##########################

$x64S1 = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x64"
$x64D1 = "\\housccm03\ScepUpdates\x64\mpam-fe.exe"
$x64S2 = "http://go.microsoft.com/fwlink/?LinkId=211054"
$x64D2 = "\\housccm03\ScepUpdates\x64\mpam-d.exe"
$x64S3 = "http://go.microsoft.com/fwlink/?LinkId=197094"
$x64D3 = "\\housccm03\ScepUpdates\x64\nis_full.exe"
$x64S4 = "http://go.microsoft.com/fwlink/?linkid=70632"
$x64D4 = "\\housccm03\ScepUpdates\x64\mpas-fe.exe"

# x86 definitions
####################
$x86S1 = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x86"
$x86D1 = "\\housccm03\ScepUpdates\x86\mpam-fe.exe"
$x86S2 = "http://go.microsoft.com/fwlink/?LinkId=211053"
$x86D2 = "\\housccm03\ScepUpdates\x86\mpam-d.exe"
$x86S3 = "http://go.microsoft.com/fwlink/?LinkId=197095"
$x86D3 = "\\housccm03\ScepUpdates\x86\nis_full.exe"
$x86S4 = "http://go.microsoft.com/fwlink/?linkid=70631"
$x86D4 = "\\housccm03\ScepUpdates\x86\mpas-fe.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($x86S1, $x86D1)
$wc.DownloadFile($x86S2, $x86D2)
$wc.DownloadFile($x86S3, $x86D3)
$wc.DownloadFile($x86S4, $x86D4)
$wc.DownloadFile($x64S1, $x64D1)
$wc.DownloadFile($x64S2, $x64D2)
$wc.DownloadFile($x64S3, $x64D3)
$wc.DownloadFile($x64S4, $x64D4)