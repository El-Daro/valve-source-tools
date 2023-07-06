function ValidateIniComment {
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

		[Parameter(Position = 5)]
		[ref]$IgnoreCommentsPattern
	)
	
	$commentLine = $($Matches.comment).Trim()
	try {
		if (
				$commentLine -ne ";" -and # An empty comment is ignored
				$commentLine -ne "#" -and
				# Skip the auto-generated comments, if asked to
				(-not ([string]::IsNullOrEmpty($IgnoreCommentsPattern)) -or $commentLine -notmatch $IgnoreCommentsPattern.Value)
			) {
			$commentKey = '[{0}.{1}]' -f $($CurrentSection.Value), $($CurrentComment.Value)	# Saves the hustle
			$newline = "`n"
			if ($IsFirstLine.Value) {
				# We don't want an empty line before the comment that occupies the first line of the .ini file
				$newline = ""
			}
			if ($Comments[$CurrentSection.Value].Contains($commentKey)) {
				$Comments[$CurrentSection.Value][$commentKey] += '{0}{1}' -f $newline, $commentLine
			} else {
				$Comments[$CurrentSection.Value].Add($commentKey, $commentLine)
			}
			$IsFirstLine.Value = $false
		}
	} Catch [System.Text.RegularExpressions.RegexParseException] {
		Write-Error "$($MyInvocation.MyCommand): $($_.Exception.Message)"
		Write-HostError -ForegroundColor Magenta -NoNewline "  An incorrect regex pattern was passed for (`""
		Write-HostError -ForegroundColor Cyan -NoNewline "IgnoreCommentsPattern"
		Write-HostError -ForegroundColor Magenta "`") parameter."
		Write-HostError -ForegroundColor Magenta "  Go and test it on regex101.com before using it here, my little coder."
	}
	 catch {
		Write-Error "$($MyInvocation.MyCommand): $($_.Exception.Message)"
		Write-HostError -ForegroundColor Magenta "$($MyInvocation.MyCommand): You're not even supposed to be here. What the hell did you do?!"
		Throw $_.Exception
	}
}