function ValidateIniSection {
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
		[ref]$IsFirstLine,

		[Parameter(Position = 5,
		Mandatory = $true)]
		[ref]$SectionCount
	)

	if ($Matches.Contains('sectionEmpty')) {
		# If the section definition is empty, generate a name for it 
		$CurrentSection.Value = "Section_$($SectionCount.Value+1)"
		$SectionCount.Value++
	} elseif ($Settings.Contains($($Matches.section).Trim())) {
		# If the section already exists, make it a current one and proceed to the next line
		$CurrentSection.Value = $($Matches.section).Trim()
		$CurrentComment.Value = $($Matches.section).Trim()
		continue
	} else {
		$CurrentSection.Value = $($Matches.section).Trim()					
	}
	$Settings.Add($CurrentSection.Value, [ordered]@{})
	$Comments.Add($CurrentSection.Value, @{})
	$CurrentComment.Value = $CurrentSection.Value			
	# If there is an in-line comment, add it to a separate dictionary
	if ($Matches.Contains('comment') -and $Matches['comment'] -ne "") {
		$Comments[$CurrentSection.Value].Add("[$($CurrentSection.Value)]", $($Matches.comment).Trim())
	}
	$IsFirstLine.Value = $false
}