function Write-HostError {
# A had-to-do-it wrapper for the built-in Write-Host cmdlet
	Param ()

	if ($ErrorActionPreference	-ne "Ignore"	-and
		$ErrorActionPreference	-ne "SilentlyContinue") {
		Write-Host @args
	}
}