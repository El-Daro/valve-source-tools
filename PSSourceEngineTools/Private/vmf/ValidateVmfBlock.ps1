function ValidateVmfBlock {
<#
	.SYNOPSIS
	Validates a block in .vmf file.

	.DESCRIPTION
	Takes an array of strings representing a .vmf formatted content as an input and transforms them into an ordered hashtable.

	.PARAMETER Lines
	An array of .vmf formatted strings. Use `Get-Content $pathToVmf` to obtain a proper array.

	.PARAMETER CurrentLine
	Represents the current line number (ref).

	.PARAMETER LinesFaulty
	Represents the current number of faulty lines (ref).

	.PARAMETER Depth
	Current depth (ref). Starts at 0, but increases for the very first block, which every .vmf file usually starts with.

	.PARAMETER Regex
	VMF-specific regex hashtable.

	.OUTPUTS
	System.Collections.Hashtable

	.NOTES
	1. See if it's the first call for the file. If so, initialize vars
	2. If we're hitting a new block, increase the Depth value. It will prevent the vars from initializing again.
	3. If we're hitting a key-value pair, validate it and to the hashtable.
		3.1. If there is no value (only the key), expect an open bracket to follow next line.
		3.2. If there is no bracket next line, terminate the execution (badly formatted .vmf).
		3.3. Otherwise increase Depth and create an inner block (go to (1)).
		3.4. If we're hitting a closing bracket, decrease Depth and return the block (go one level up).
	4. Comments and empty lines are ignored.
	5. Any line that doesn't adhere to the rules described above is ignored, but a counter for faulty lines is increased.
#>

	Param(
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[ref]$CurrentLine,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$LinesFaulty,

		[Parameter(Position = 3,
		Mandatory = $true)]
		[ref]$Depth,

		[Parameter(Position = 4,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Regex
	)

	#region VARIABLES
	$currentKey			= ""
	$currentBlock		= [ordered]@{}
	$bracketExpected	= $false
	#endregion

	while ($currentLine.Value -lt $Lines.count) {
		switch -regex ($Lines[$CurrentLine.Value]) {
			# A key-value pair
			"$($regex.keyValue)" {
				# Write-Debug "$($currentLine.Value + 1). ---Key-Value---"
				# Write-Debug "$($currentLine.Value + 1): $_"
				$params = @{
					CurrentLine		= $CurrentLine
					CurrentBlock	= $currentBlock
					BracketExpected	= [ref]$bracketExpected
				}
				$currentKey = ValidateVmfKeyValue @params
				$CurrentLine.Value++
				continue
			}

			# An open bracket
			"$($regex.bracketOpen)" {
				# Write-Debug "$($currentLine.Value + 1). --Open-bracket--"
				# Write-Debug "$($currentLine.Value + 1): $_"
				if ($bracketExpected) {
					$bracketExpected = $false
					$currentLine.Value++
					$Depth.Value++
					$params = @{
						Lines		= $Lines
						CurrentLine	= $currentLine
						LinesFaulty	= $linesFaulty
						Depth		= $Depth
						Regex		= $Regex
					}
					$currentBlock[$currentKey] = ValidateVmfBlock @params
				} else {
					throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '{' at line $($currentLine.Value + 1)."
				}
				continue
			}

			# A close bracket
			"$($regex.bracketClose)" {
				# Write-Debug "$($currentLine.Value + 1). --Close-bracket--"
				# Write-Debug "$($currentLine.Value + 1): $_"
				$currentLine.Value++
				$Depth.Value--
				if ($Depth.Value -lt 0) {
					throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
				}
				return $currentBlock
			}

			# A single-line comment
			"$($regex.comment)" {
				$currentLine.Value++
				#Write-Debug "$($currentLine.Value + 1). ----Comment----"
				#Write-Debug "$($currentLine.Value + 1): $_"
				continue
			}

			default {
				if ($_ -notmatch "$($regex.emptyLine)") {
					$linesFaulty.Value++
					#Write-Verbose "An unidentified content on line $($currentLine.Value + 1): $_"
					if (-not $PSBoundParameters.ContainsKey('Verbose')) {
						#Write-Debug "UNDEFINED (line $($currentLine.Value + 1)): $_"
					}
				}
				$currentLine.Value++
			}
		}

		if ($currentLine.Value -ge 100 -and $currentLine.Value % 100 -eq 0) { 
			$params = @{
				CurrentLine	= $currentLine.Value
				LinesCount	= $Lines.count
			}
			ReportProgress @params
		}
	}

	if ($VerbosePreference -ne "SilentlyContinue"){
		ReportStatistics -LinesCount $currentLine.Value -LinesFaulty $linesFaulty.Value
	}

	return $currentBlock
}