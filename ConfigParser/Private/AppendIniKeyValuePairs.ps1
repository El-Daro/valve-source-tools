function AppendIniKeyValuePairs {
	<#
		.SYNOPSIS
		Appends Key-Value pairs to the StringBuilder object.
	
		.DESCRIPTION
		Formats INI-specific key-value pairs provided via hashtables to a simple string representation in StringBuilder.
		Note that all parameters are mandatory.
	
		.PARAMETER StringBuilder
		StringBuilder object contains the whole .ini formatted string that needs to be modified.
	
		.PARAMETER Section
		INI section name.
	
		.PARAMETER Settings
		Main INI settings. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
		containing sections of the .ini format.
	
		.PARAMETER Comments
		INI comments. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
		containing sections of the .ini format.
	
		.PARAMETER IncludeComments
		User-specified parameter that determines whether to include comments or not.
	
		.PARAMETER IsFirstLine
		This flag determines whether the current line is first or not. Does not affect execution of this function,
		however, it can be set here, which affects execution of the whole module in other areas.
	
		.PARAMETER IsLastLineComment
		This flag is raised when the last processed line was a comment line. Does not affect execution of this function,
		however, it can be set here, which affects execution of the whole module in other areas.
	#>
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$StringBuilder,

		[Parameter(Position = 1,
		Mandatory = $true)]
		$Section,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Settings,

		[Parameter(Position = 3,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Comments,

		[Parameter(Position = 4,
		Mandatory = $true)]
		[ref]$IncludeComments,

		[Parameter(Position = 5,
		Mandatory = $true)]
		[ref]$IsFirstLine,

		[Parameter(Position = 6,
		Mandatory = $true)]
		[ref]$IsLastLineComment
	)

	$lengthMax = EvaluateIniMaxLineLength -Settings $Settings -Section $Section

	foreach ($key in $Settings[$Section].Keys) {
		[void]$StringBuilder.Value.AppendFormat('{0}{1} = "{2}"', "`n", $key, $Settings[$Section][$key])
		$IsFirstLine.Value = $false
		$IsLastLineComment.Value = $false
		if ($IncludeComments.Value -and $Comments.Contains($Section)) {
			# If the section is in the Comments dictionary
			if ($Comments[$Section].Contains($key))	{
				# and the current key from the said section has an in-line comment
				# Add it to the output
				$length = $key.Length + $Settings[$Section][$key].Length + 5	# Length of the current Key-Value line
				# Difference between current line length and the max line length. If it's negative, assume 0
				[double]$charDiff = [math]::Max($lengthMax - $length, 0)
				$tabsCount = ([math]::Ceiling($charDiff / 4 ))
				[void]$StringBuilder.Value.AppendFormat('{0}{1}', "".PadRight($tabsCount, "`t"), $Comments[$Section][$key])
			}
			if ($Comments[$section].Contains("[$section.$key]")) {
				# If there is a proceeding single-line comment, add it to the output
				[void]$StringBuilder.Value.AppendFormat('{0}{0}{1}', "`n", $Comments[$Section]["[$Section.$key]"])
				$IsLastLineComment.Value = $true
			}
		}
	}
}