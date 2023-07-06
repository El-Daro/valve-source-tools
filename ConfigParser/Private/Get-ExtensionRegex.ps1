function Get-ExtensionRegex {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string]$Extension
	)

	if ($Extension -eq ".vdf") {
		return "^(?:.+)\.vdf`"*'*`$"
	} elseif ($Extension -eq ".ini") {
		return "^(?:.+)\.(ini|cfg)`"*'*`$"
	}
}