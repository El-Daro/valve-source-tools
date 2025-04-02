function Get-AbsolutePath {
<#
	.SYNOPSIS
	Returns an absolute path.

	.DESCRIPTION
	The function takes both absolute and relative path as an input and returns the absolute path.
	
	.PARAMETER Path
	Specifies the path. Accepts absolute and relative paths. Does NOT accept wildcards.
#>
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string]$Path
	)

	if ($Path -match "^[.]+\\") {
		return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
	} else {
		return $Path
	}
}