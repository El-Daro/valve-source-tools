function Get-ExtensionRegex {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string]$Extension
	)

	if ($Extension -eq ".vdf") {
		return "^(?:.+)\.vdf`"*'*`$"
	} elseif ($Extension -eq ".vmf") {
		return "^(?:.+)\.vmf`"*'*`$"
	} elseif ($Extension -eq ".ini") {
		return "^(?:.+)\.(ini|cfg)`"*'*`$"
	} elseif ($Extension -eq ".txt" -or $Extension -eq ".log") {
		return "^(?:.+)\.(txt|log)`"*'*`$"
	}
}