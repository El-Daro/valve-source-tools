# TODO: Cleanup

using namespace System.Diagnostics

function ConvertFrom-Stripper {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	#region Preparing shared variables
	$linesFaulty		= 0
	$currentLine		= 0
	$currentMode		= 'filter'		# filter=remove | add | modify=replace
	$currentSubmode		= 'none'		# none | match | replace | delete=remove | insert
	$currentBlock		= [ordered]@{}
	$stripper			= [ordered]@{	# This gets populated with currentBlock on bracket close
		filter			= [System.Collections.Generic.List[ordered]]::new()
		add				= [System.Collections.Generic.List[ordered]]::new()
		modify			= [System.Collections.Generic.List[ordered]]::new()
	}
	# $currentSubmodeCounter = 0			# Should actually be the List.Length - 1
	# Only add when found
	# $stripper["modify"].Add([ordered]@{
	# 	match	= [ordered]@{};
	# 	replace	= [ordered]@{};
	# 	delete	= [ordered]@{};
	# 	insert	= [ordered]@{}
	# })
	$stackBlocks		= [System.Collections.Generic.Stack[ordered]]::new()
	# $estimatedMilliseconds	= 0
	$progressCounter	= 0
	$progressStep		= $Lines.Count / 5
	$regex				= Get-StripperRegex
	#endregion

	try  {

		$sw = [Stopwatch]::StartNew()
		# All the logic is in this private function
		# $params			= @{
		# 	Lines		= $Lines
		# 	CurrentLine	= [ref]$currentLine
		# 	LinesFaulty	= [ref]$linesFaulty
		# 	Stopwatch	= [ref]$sw
		# }
		# return ParseStripperBlock @params

		#region NEW CODE
		
		while ($currentLine -lt $Lines.count) {

			#region REGEX
			<#
			switch -regex ($Lines[$CurrentLine]) {
				# A key-value pair
				"$($regex.keyValue)" {
					Write-Debug "$($currentLine + 1). ---Key-Value---"
					Write-Debug "$($currentLine + 1): $_"
					# $params = @{
					# 	CurrentLine		= $CurrentLine
					# 	CurrentBlock	= $currentBlock
					# 	BracketExpected	= [ref]$bracketExpected
					# }
					# $currentKey = ValidateVdfKeyValue @params
					$CurrentLine++
					continue
				}

				# An open bracket
				"$($regex.bracketOpen)" {
					Write-Debug "$($currentLine + 1). --Open-bracket--"
					Write-Debug "$($currentLine + 1): $_"
					if ($bracketExpected) {
						$bracketExpected = $false
						$currentLine++
						$Depth++
						# $params = @{
						# 	Lines		= $Lines
						# 	CurrentLine	= $currentLine
						# 	LinesFaulty	= $linesFaulty
						# 	Depth		= $Depth
						# 	Regex		= $Regex
						# }
						# $currentBlock[$currentKey] = ValidateVdfBlock @params
					} else {
						Write-Debug "Undefined block"
						# throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '{' at line $($currentLine.Value + 1)."
					}
					continue
				}

				# A close bracket
				"$($regex.bracketClose)" {
					Write-Debug "$($currentLine + 1). --Close-bracket--"
					Write-Debug "$($currentLine + 1): $_"
					$currentLine++
					$Depth--
					if ($Depth -lt 0) {
						Write-Debug "Unexpected '}'"
						# throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
					}
					return $currentBlock
				}

				# Mode identificator
				"$($regex.mode)" {
					$currentLine++
					$bracketExpected = $true
					$currentMode = $Matches["mode"]
					Write-Debug "$($currentLine). -----Mode------"
					Write-Debug "$($currentLine): $_"
					continue
				}

				# Mode identificator
				"$($regex.subMode)" {
					Write-Debug "$($currentLine). ----SubMode----"
					Write-Debug "$($currentLine): $_"
					$currentLine++
					$bracketExpected = $true
					if ($currentMode -ne "modify") {
						# Ignore?
						Write-Debug "A sub-mode was announced not in a proper mode (modify)"
						Write-Debug "Current mode: $currentMode"
					} else {
						$currentSubmode = $Matches["subMode"]
					}
					continue
				}

				# A single-line comment
				"$($regex.comment)" {
					$currentLine++
					Write-Debug "$($currentLine). ----Comment----"
					Write-Debug "$($currentLine): $_"
					continue
				}

				default {
					if ($_ -notmatch "$($regex.emptyLine)") {
						$linesFaulty++
						Write-Verbose "An unidentified content on line $($currentLine + 1): $_"
						if (-not $PSBoundParameters.ContainsKey('Verbose')) {
							Write-Debug "UNDEFINED (line $($currentLine + 1)): $_"
						}
					}
					$currentLine++
				}
			}
			#>
			#endregion

			#region Char comparison:
			$line = $Lines[$currentLine].Trim()
			if ($line.Length -lt 1) {
				$currentLine++
				continue
			}
			if ($line[0] -eq "`"") {
				# Key-value
				# Write-Debug "$($currentLine + 1). ---Key-Value---"
				Write-Debug "$($currentLine + 1): $line"
				# Validation
				# Actually need to employ some regex validation
				if ($line -match "$($regex.keyValue)") {
					$key	= $Matches["key"]
					$value	= $Matches["value"]
					if (-not $currentBlock.Contains($key)) {
						$currentBlock[$key] = [System.Collections.Generic.List[string]]::new()
					}
					$currentBlock[$key].Add($value)
				}
				# $property	= $line.SubString(1, $line.Length - 2) -split "`" `""

			} elseif ($line[0] -eq '{') {
				# Start block
				# Write-Debug "$($currentLine + 1). --Open-bracket--"
				Write-Debug "$($currentLine + 1): $line"
				# if ($bracketExpected) {
				# 	$bracketExpected = $false
					# $currentLine++
					$Depth++
					if ($Depth -gt 1) {
						$stackBlocks.Push($currentBlock)
					}
					# $currentBlock	= [ordered]@{ }
					if ($currentMode -eq "modify" -and $Depth -eq 1) {
						# $stripper[$currentMode].Add([ordered]@{
						# 	match	= [ordered]@{};
						# 	replace	= [ordered]@{};
						# 	delete	= [ordered]@{};
						# 	insert	= [ordered]@{}
						# })
						$currentBlock	= [ordered]@{
							match	= [ordered]@{};
							replace	= [ordered]@{};
							delete	= [ordered]@{};
							insert	= [ordered]@{}
						}
						# $stripper[$currentMode].Add($currentBlock)
					} else {
						$currentBlock	= [ordered]@{ }
					}
					# $params = @{
					# 	Lines		= $Lines
					# 	CurrentLine	= $currentLine
					# 	LinesFaulty	= $linesFaulty
					# 	Depth		= $Depth
					# 	Regex		= $Regex
					# }
					# $currentBlock[$currentKey] = ValidateVdfBlock @params

				# } else {
				# 	Write-Debug "Undefined block"
					# throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '{' at line $($currentLine.Value + 1)."
				# }
			} elseif ($line[0] -eq '}') {
				# End block
				# Write-Debug "$($currentLine + 1). --Close-bracket--"
				Write-Debug "$($currentLine + 1): $line"
				$Depth--
				# $bracketExpected = $true
				if ($Depth -lt 0) {
					Write-Debug "Unexpected '}'"
					# throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
				}
				if ($currentMode -eq "modify") {
					if ($Depth -eq 0) {				# If we are exiting the "modify" block
						# $currentSubmodeCounter++
						$stripper[$currentMode].Add($currentBlock)
					} else {
						$parentBlock = $stackBlocks.Pop()
						$parentBlock[$currentSubmode] = $currentBlock
						$stackBlocks.Push($parentBlock)
						# $stripper[$currentMode][$currentSubmodeCounter][$currentSubmode] = $currentBlock
					}
					$currentSubmode = "none"
				} else {
					$stripper[$currentMode].Add($currentBlock)
				}
				if ($Depth -gt 0 -and $stackBlocks.Count -gt 0) {
					$currentBlock = $stackBlocks.Pop()
				}
			} elseif (($line[0] -eq ';') -or
					  ($line[0] -eq '#') -or
					  ($line.Length -gt 1 -and $line[0] -eq '/' -and $line[1] -eq '/')) {
	  			# Comments are ignored
				# Write-Debug "$($currentLine + 1). ----Comment----"
				Write-Debug "$($currentLine + 1): $line"
			} else {
				# Do regex match on a mode and sub-mode
				if ($line -match "$($regex.mode)") {
					# That's a mode
					# Write-Debug "$($currentLine + 1). -----Mode------"
					Write-Debug "$($currentLine + 1): $line"
					# $bracketExpected = $true
					$currentMode	= $Matches["mode"]
					# if ($currentMode -eq "modify") {
					# 	$stripper[$currentMode].Add([ordered]@{
					# 		match	= [ordered]@{};
					# 		replace	= [ordered]@{};
					# 		delete	= [ordered]@{};
					# 		insert	= [ordered]@{}
					# 	})
					# }
					# $currentBlock	= [ordered]@{ }
					
					# Class names are NOT enclosed in quotation marks
					# $CurrentLine += 1				# Jump over the open bracket
					# if (-not $currentBlock["classes"].Contains($line)) {
					# 	$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
					# }

					# Create a new block for the class
					# $newBlock = [ordered]@{	}
					# $stripper[$currentMode].Add([ordered]@{ })

					# Do we need to use stack? I think not
					# $stackBlocks.Push($currentBlock)
					# $currentBlock = $newBlock
				} elseif ($line -match "$($regex.subMode)") {
					# That's a sub-mode
					# Write-Debug "$($currentLine + 1). ----SubMode----"
					Write-Debug "$($currentLine + 1): $line"
					# $bracketExpected	= $true
					if ($currentMode -ne "modify") {
						# Ignore?
						Write-Debug "A sub-mode was announced not in a proper mode (modify)"
						Write-Debug "Current mode: $currentMode"
					} else {
						$currentSubmode	= $Matches["subMode"]
						Write-Debug "Current sub-mode: $currentSubmode"
						
						# $currentBlock	= [ordered]@{ }
					}
				}

				<#
				switch -regex ($Lines[$currentLine]) {
					"$($regex.mode)" {
						# That's a mode
						$bracketExpected = $true
						$currentMode = $Matches["mode"]
						Write-Debug "$($currentLine). -----Mode------"
						Write-Debug "$($currentLine): $_"
					}

					"$($regex.subMode)" {
						# That's a sub-mode
						Write-Debug "$($currentLine). ----SubMode----"
						Write-Debug "$($currentLine): $_"
						$bracketExpected = $true
						if ($currentMode -ne "modify") {
							# Ignore?
							Write-Debug "A sub-mode was announced not in a proper mode (modify)"
							Write-Debug "Current mode: $currentMode"
						} else {
							$currentSubmode = $Matches["subMode"]
							Write-Host "Current sub-mode: $currentSubmode"
						}
					}
				}
				#>
			}

			#endregion


			# VMF parser:
			<#
			$line = $Lines[$CurrentLine].Trim()
			if ($line[0] -eq "`"") {
				# If line starts with double quote, it's a property
				$property		= $line.SubString(1, $line.Length - 2) -split "`" `""
				if (-not $currentBlock["properties"].Contains($property[0])) {
					$currentBlock["properties"][$property[0]] = [System.Collections.Generic.List[string]]::new()
				}
				$currentBlock["properties"][$property[0]].Add($property[1])
	
			} elseif ($line[0] -eq "}") {
				# If a line starts with closed bracket, it means we can stop parsing the class and return one level up
				if ($stackBlocks.Count -gt 0) {
					$currentBlock = $stackBlocks.Pop()
				} else {
					# If we ended up this route, it means that VMF is badly formatted
					throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
				}
			} elseif ([string]::IsNullOrWhiteSpace($line) -or $line[0] -eq "/") {
				# Write-Debug "Empty line or a comment"
			} else {
				# The input is strict, so we can omit additional checks and safely assume that everything else is a class name
				# In VMF class names are NOT enclosed in quotation marks
				$CurrentLine += 1				# Jump over the open bracket
				if (-not $currentBlock["classes"].Contains($line)) {
					$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
				}
				# Create a new block for the class
				$newBlock = [ordered]@{
					properties = [ordered]@{}
					classes    = [ordered]@{}
				}
				$currentBlock["classes"][$line].Add($newBlock)
				$stackBlocks.Push($currentBlock)
				$currentBlock = $newBlock
			}
			#>
			
			$CurrentLine += 1
	
			if ($Lines.Count -gt 10000 -and $currentLine -ge $progressStep -and [math]::Floor($currentLine / $progressStep) -gt $progressCounter) { 
				$progressCounter++
				$elapsedMilliseconds = $sw.ElapsedMilliseconds
				$estimatedMilliseconds = ($Lines.Count / $currentLine) * $elapsedMilliseconds
				$params = @{
					CurrentLine				= $currentLine
					LinesCount				= $Lines.count
					EstimatedMilliseconds	= $estimatedMilliseconds
					ElapsedMilliseconds		= $sw.ElapsedMilliseconds
					Activity				= "Parsing..."
				}
				ReportProgress @params
			}
	
		}
		#endregion
		return $stripper


	} catch [FormatException] {
		Write-Error -Message "$($_.Exception.Message)"
		Write-HostError -ForegroundColor DarkYellow -NoNewline "`tCheck the file "
		Write-HostError -ForegroundColor Cyan -NoNewline "`"$(Get-AbsolutePath -Path $Path)`" "
		Write-HostError -ForegroundColor DarkYellow "for any missing curly brackets or bracket keys."
		Throw $_.Exception
	} catch {
		Write-Error "$($MyInvocation.MyCommand): Error processing the input file."
		if (				 $null	-ne $currentLine -and
			$ErrorActionPreference	-ne "Ignore"	-and
			$ErrorActionPreference	-ne "SilentlyContinue") {
			ReportLine -Path (Resolve-Path $Path) -CurrentLine $Lines[$currentLine] -LinesCount $currentLine
		}
		Throw $_.Exception
	} finally {
		$sw.Stop()

		if (-not $Silent.IsPresent) {
			$linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			OutLog 							-Value "`nStripper | Parsing: Complete"					-Path $LogFile -OneLine
			OutLog -Property "Parsed lines"	-Value $("{0} / {1}" -f $currentLine, $Lines.Count)		-Path $LogFile
			if ($linesFaulty -gt 0) {
				OutLog -Property "Faulty lines"	-Value $("{0} / {1}" -f $linesFaulty, $Lines.Count)	-Path $LogFile
			}
			OutLog -Property "Elapsed time"	-Value $timeFormatted									-Path $LogFile
			OutLog -Property "Speed"		-Value $("{0:n0} lines per second" -f $linesPerSecond)	-Path $LogFile
		}
	}
}