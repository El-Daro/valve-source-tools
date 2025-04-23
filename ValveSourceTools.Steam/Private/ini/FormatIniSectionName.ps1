function FormatIniSectionName {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$Section,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[ref]$IsFirstLine,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$IsLastLineComment
	)

	$newline = ""
	if (-not $IsFirstLine.Value) {
		$newline = "`n"
		if (-not $IsLastLineComment.Value) {
			$newline = "`n`n"
		}
	}
	$IsFirstLine.Value = $false
	$IsLastLineComment.Value = $false
	return '{0}[{1}]' -f $newline, $Section
}