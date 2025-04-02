function ValidateIniKeyValue {
	# If it works, it works. Don't touch this function — you don't even know what it's doing anymore.
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

	#region VARIABLES
	$key		= $($Matches.key).Trim()
	$value		= $($Matches.value).Trim()
	# The script accepts both single- and double-quotes,
	# but you cannot escape the comment symbols, if these characters are different.
	# So we have to assume that the first one is the one that was INTENDED as a quote character.
	$quoteChar	= $null
	$firstIndex	= 0				# For a substring that will be matched later
	$length		= $value.Length	# 
	$comment	= $false		# 
	#endregion
	
	###############################SHITCODE-START####################################
	# A shitcode masterpiece:
	if ($Matches.Contains('quoteCharacter') -and $value.LastIndexOf($Matches['quoteCharacter']) -ne 0) {
		# If the value starts with one of two quote characters AND it's not the only one
		# We allow comment symbols here (';', '#') that cause all the trouble below
		$quoteChar = $Matches['quoteCharacter']
		$firstIndex++						# Advance the beginning of a temp substring one character further
		$length--							# Decrease the whole length because of that
		if ($value[-1] -eq $quoteChar) {	# If the string ends with the same quote character
			$length--						# Prepare the upper boundary for a substring
		}
		$valueIsolated = $($value.Substring($firstIndex, $length))
			# Isolate a substring inside the surrounding quotes,
			# see if it has any more quote chars before any of the last comment chars
		if (($valueIsolated.LastIndexOfAny(";#") -gt 			# A comment symbol exists ('cause otherwise it's -1)
					$valueIsolated.IndexOf($quoteChar) -and		# and it is after the quote symbol
					$valueIsolated.IndexOf($quoteChar) -ne -1) -or	# AND The quote symbol exists, too
				$valueIsolated.LastIndexOfAny(";#") -eq -1) {	# OR there is no comment at all
			# If it does, validate as quoted with a comment
			if ($value -match $regex.value.quoted) {
				$tempValue = $($Matches.value).Trim()	# Alas, this step is necessary, 'cause the shit is broken
					# Does it start and end with a quote char now?
				if ($tempValue[0] -eq $quoteChar -and $tempValue[($tempValue.Length-1)] -eq $quoteChar) {
					Write-Debug "Evaluated as properly quoted value: $value"
					# Trim it, if so. We don't use .Trim() function, because it would get rid of all the quote symbols
					$value = $tempValue.Substring(1, $tempValue.Length-2)
				} else {
					Write-Debug "Evaluated as improperly quoted value: $value"
					$value = $tempValue				# Otherwise we keep the starting quote character as a part of the string
				}
				if ($Matches.Contains('comment') -and $Matches['Comment'] -ne "") {
					# We already made sure that a value exists, but in-line comment is under question
					$comment = [string]$Matches.comment	# No need to trim here, as it is already captured without whitespaces
					Write-Debug "`tIn-line comment: $comment"
				}
			} else {
				# This is an exception
				Write-Debug "Failed to validate as quoted with a comment (a quote character before the comment does exist)"
				Write-Debug "Issue: $_"
				continue
			}
		} elseif ($value[-1] -eq $quoteChar) {
			# If a string is definitely enclosed in only quote characters, just capture almost everything
			if ($value -match $regex.value.commentPattern) {
				# Alas, it seems like there is a comment pattern inside,
				# which is described by one or more TAB characters, followed by a comment character (';' or '#')
				if ($value -match $regex.value.unquoted) {
					Write-Debug "Tabbed comments detected inside a fully-quoted line: $value"
					$value = $($Matches.value).Trim()
					if ($Matches.Contains('comment') -and $Matches['Comment'] -ne "") {
						# This is not a design flaw, but just a precaution in case the assumption was wrong
						$comment = [string]$Matches.comment		# No need to trim here, as it is already trimmed
						Write-Debug "`tIn-line comment: $comment"
					} else {
						Write-Debug "`tExceptional case: regex didn't grab the tabbed comment!"
					}
				} else {
					# This is an exception
					Write-Debug "Failed to validate as a simple value (only a starting quote character exists)"
					Write-Debug "Issue: $_"
					continue
				}
			} else {
				if ($value -match $regex.value.unquotedNoComments) {
					$tempValue = $($Matches.value).Trim()	# Alas, this step is necessary, 'cause the shit is broken
						# Does it start and end with a quote char now?
					if ($tempValue[0] -eq $quoteChar -and $tempValue[($tempValue.Length-1)] -eq $quoteChar) {
						Write-Debug "Evaluated as properly quoted value with NO comments: $value"
						# Trim it, if so. We don't use .Trim() function, because it will get rid of all the quote symbols
						$value = $tempValue.Substring(1, $tempValue.Length-2)
					} else {
						Write-Debug "Evaluated as improperly quoted value with NO comments: $value"
						$value = $tempValue			# Otherwise we keep the starting quote character as a part of the string
					}
				} else {
					# This is an exception
					Write-Debug "Failed to validate as quoted with a comment (a quote character before the comment does exist)"
					Write-Debug "Issue: $_"
					continue
				}
			}	
		} else {
			# Otherwise it's clearly a string that only has one quote character in the beginning and some after the comment
			# So validate it as a simple value
			if ($value -match $regex.value.unquoted) {
				Write-Debug "Evaluated as improperly quoted value: $value"
				$value = $($Matches.value).Trim()
				if ($Matches.Contains('comment') -and $Matches['Comment'] -ne "") {
					# We already made sure that a value exists, but in-line comment is under question
					$comment = [string]$Matches.comment		# No need to trim here, as it is already trimmed
					Write-Debug "`tIn-line comment: $comment"
				}
			} else {
				# This is an exception
				Write-Debug "Failed to validate as a simple value (only a starting a quote character exists)"
				Write-Debug "Issue: $_"
				continue
			}
		}
	##############################################
	} else {
		# Otherwise it's a simple, unquoted value
		# Consider working with a substring, yo
		if ($value -match $regex.value.unquoted) {
			Write-Debug "Evaluated as unquoted value: $value"
			$value = $($Matches.value).Trim()
			if ($Matches.Contains('comment') -and $Matches['Comment'] -ne "") {
				# We already made sure that a value exists, but in-line comment is under question
				$comment = [string]$Matches.comment		# No need to trim here, as it is already trimmed
				Write-Debug "`tIn-line comment: $comment"
			}
		} else {
			# This is an exception
			Write-Debug "Failed to validate as a simple value (only a starting a quote character exists)"
			Write-Debug "Issue: $_"
			continue
		}
	}
	####################################SHITCODE-END######################################				
	if ($Settings[$CurrentSection.Value].Contains($key)) {
		# If a key already exists, update it with the new value
		$Settings[$CurrentSection.Value].Item($key) = $value
		if ($comment) {
			# If the line containts a comment, add it to a separate dictionary
			$Comments[$CurrentSection.Value].Item($key) = $comment
		}
	} else {
		# Otherwise create a new key
		$Settings[$CurrentSection.Value].Add($key, $value)
		if ($comment) {
			# If the line containts a comment, add it to a separate dictionary
			$Comments[$CurrentSection.Value].Add($key, $comment)
		}
		$CurrentComment.Value = $key
	}
	$IsFirstLine.Value = $false
}