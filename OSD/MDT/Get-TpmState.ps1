param
(

)

# Gather TPM State
$tpm = Get-WmiObject -Class win32_tpm -Namespace root\cimv2\security\microsofttpm
$tpmState = ($tpm.IsOwned()).IsOwned

# Load TS Environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Set variable
$tsenv.Value('TpmIsOwned') = $tpmState