# TODO: See if the commented part of the 'if' statement needs to stay or go.
function ValidateVdfKeyValue {
<#
	.SYNOPSIS
	Validates a key-value pair in the .vdf format file.

	.DESCRIPTION
	Takes the current line number as an input, validates a corresponding key-value pair and adds it to the block.

	.PARAMETER CurrentLine
	Represents the current line number.

	.PARAMETER CurrentBlock
	A hashtable that contains all the currently validated key-value pairs.

	.PARAMETER BracketExpected
	Specifies whether an opening curly bracket is expected. Triggered by a key-value pair that doesn't have the value.
#>

	Param(
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$CurrentLine,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$CurrentBlock,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$BracketExpected
	)

	if ($BracketExpected.Value) {
		Write-Error "Could not validate the .vdf file."
		Write-HostError -ForegroundColor Red -NoNewline "`tAn open bracket is expected on "
		Write-HostError -ForegroundColor Cyan -NoNewline "line $($CurrentLine.Value + 1)"
		Write-HostError -ForegroundColor Red ". Instead got:"
		Write-HostError -ForegroundColor DarkYellow "$_"
		Throw $_.Exception
	} else {
		$key = $($Matches.key).Trim()
		if ($Matches.Contains('valueQuoted')) {
			$value = $($Matches.value).Trim()
			$CurrentBlock[$key] = $value
		} else {
			$BracketExpected.Value = $true
		}
	}
	return $key
}