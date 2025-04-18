function ValidateIniInvalidValue {
	Param(
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Settings,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Comments,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$CurrentSection,

		[Parameter(Position = 3,
		Mandatory = $true)]
		[ref]$CurrentComment,

		[Parameter(Position = 4,
		Mandatory = $true)]
		[ref]$IsFirstLine
	)

	$key = $($Matches.key).Trim()
	if ($Settings[$CurrentSection.Value].Contains($key)) {
		continue
	} else {
		# If a key is presented without a value, assume it's an empty string
		$Settings[$CurrentSection.Value].Add($key, "")
		if ($Matches.Contains('comment') -and $Matches['Comment'] -ne "") {
			# If the line containts a comment, add it to a separate dictionary
			$Comments[$CurrentSection.Value].Add($key, $($Matches.comment).Trim())
		}
		$CurrentComment.Value = $key
	}
	$IsFirstLine.Value = $false
}