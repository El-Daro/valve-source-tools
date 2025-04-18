# Problem: VMF files contain a lot of 'key-value' pairs with the same key
# Might have to ditch the dictionary principle

# DONE: Do we even need the `world` section? Shouldn't we just preserve it as is?
#		Are there the same problems with `entities`? If not, then it's not important to solve
# Answ: Alas, the issue persists
# Sol : Consider using id's. They seem to be unique and ubiquitos
# NOTE: Not every pair of curly brackets comes with id

# DONE: Fix a weird 'String doesn't have .Add method' bug
#		Line: 292791 / 478328
# Cause: Properties and classes might have the same name
# Soln: Enclose props in the 'properties' dict
# DONE: Output the parsed file

# TODO: Create its own set of functions for VMF parsing
# TODO: Optimize performance
# 		- See how regex affects the speed of the processing
#			Seems to be little to no effect
#		- It seems that calling the function from inside causes a lot of speed lost
#			Try going through the input to estimate the size of the ArrayList that you need to allocate
# NOTE: Speed halves each time you double the input size
# SOLN: Solved it by creating a different function with unpacked recursion
#		Will leave this one for historical purposes
#		Average parsing time (478k lines):
#			This: 6 min
#			 New: 6 sec

# TODO: Cleanup

function ParseVmfBlockRecursive {

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
			
			[Parameter(Position = 5,
			Mandatory = $false)]
			[ref]$StopWatch,

			[Parameter(Position = 6,
			Mandatory = $false)]
			[ref]$EstimatedMilliseconds,
		
			[Parameter(Position = 7,
			Mandatory = $false)]
			[ref]$ProgressCounter = [ref]0,
			
			[Parameter(Position = 8,
			Mandatory = $false)]
			$ProgressStep = 1000,
			
			[Parameter(Position = 9,
			Mandatory = $false)]
			[ref]$ToEstimate = [ref]$True
		)
	
		#region VARIABLES
		$currentBlock	= [ordered]@{
			properties	= [ordered]@{};
			classes		= [ordered]@{}
		}
		$propertyCount	= 0
		$classCount		= 0
		$classLength	= 0
		#endregion
	
		#region New code
		# Got rid of regex
		# Got rid unnecessary checks
		while ($currentLine.Value -lt $Lines.count) {
			if ($Depth.Value -gt 0) {
				$classLength++
			}

			$line = $Lines[$CurrentLine.Value].Trim()
			if ($line[0] -eq "`"") {
				$line			= $line.Trim("`"")
				$skip			= $false
				$sbPropName		= [System.Text.StringBuilder]::new(32)
				$sbPropValue	= [System.Text.StringBuilder]::new(128)
				# $propertyName	= ""
				# $propertyValue	= ""
				# $string			= [ref]$propertyName
				$string			= [ref]$sbPropName
				foreach ($char in $line.GetEnumerator()) {
					if ($char -eq "`"") {
						if ($skip) {	# Switch the stringBuilder (to start saving the value to it later)
							# $string = [ref]$propertyValue
							$string = [ref]$sbPropValue
						}							# Raise the flag
						$skip = -not $skip			# Continue until another match
					} elseif (-not $skip) {
						# $string.Value += $char		# Add the char to a new string
						[void]$string.Value.Append($char)
					}
				}
				$propertyName	= $sbPropName.ToString()
				$propertyValue	= $sbPropValue.ToString()
				if (-not $currentBlock["properties"].Contains($propertyName)) {
				# if (-not $currentBlock["properties"].ContainsKey($sbPropName.ToString())) {
					# $currentBlock["properties"][$propertyName] = [ordered]@{}
					# $currentBlock["properties"][$propertyName] = New-Object System.Collections.Generic.List[string]
					$currentBlock["properties"][$propertyName] = [System.Collections.Generic.List[string]]::new()

				}
				# $currentBlock["properties"][$propertyName][$propertyCount.ToString()] = $propertyValue
				$currentBlock["properties"][$propertyName].Add($propertyValue)
				$propertyCount++

			} elseif ($line[0] -eq "}") { #-and $line.Length -eq 1) {
				$currentLine.Value++
				$Depth.Value--
				if ($Depth.Value -lt 0) {
					throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
				}
				return $currentBlock
				# return [ordered]@{}
			} else {
				# Check next line. If it is `{`, start processing a section
				# if ($Lines[$CurrentLine.Value + 1].Trim() -eq "{") {
					$CurrentLine.Value += 2
					$Depth.Value++
					# $currentKey = $line
					# if (-not $currentBlock["classes"][$currentKey]) {
					if (-not $currentBlock["classes"].Contains($line)) {
						# $currentBlock["classes"][$currentKey] = [ordered]@{}
						if ($line -eq "entity" -or $line -eq "solid") {
							$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new(8000)
						} else {
							$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
						}
						# $currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
					}
					$params = @{
						Lines					= $Lines
						CurrentLine				= $currentLine
						LinesFaulty				= $linesFaulty
						Depth					= $Depth
						StopWatch				= $StopWatch
						EstimatedMilliseconds	= $EstimatedMilliseconds
						ProgressCounter			= $ProgressCounter
						ProgressStep			= $ProgressStep
						ToEstimate				= $ToEstimate
					}
					$currentBlock["classes"][$line].Add($(ParseVmfBlockRecursive @params))	# sectionCount is sort of an ID
					# $currentBlock["classes"][$currentKey].Add($classCount.ToString(), $(ParseVmfBlockRecursive @params))	# sectionCount is sort of an ID
					# $currentBlock["classes"][$currentKey].Add($classCount.ToString(), "Parsed block placeholder")	# sectionCount is sort of an ID
					$classCount++		# It's needed because any given class can contain multiple classes of the same name
					continue
				# } else {
				# 	throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '{' at line $($currentLine.Value + 1)."
				# }

			}

			$CurrentLine.Value += 1
			
			# if ($currentLine.Value -ge 10000 -and $currentLine.Value % 10000 -eq 0) { 
			if ($ToEstimate.Value -and $currentLine.Value -ge $($ProgressStep * 10) -and [math]::Floor($currentLine.Value / ($ProgressStep * 10)) -eq 1) { 
				$ToEstimate.Value = $False
				$elapsedMilliseconds = $StopWatch.Value.ElapsedMilliseconds
				$EstimatedMilliseconds.Value = ($Lines.Count / $currentLine.Value) * $elapsedMilliseconds
			}
			# if ($currentLine.Value -ge 1000 -and $currentLine.Value % 1000 -eq 0) { 
			if ($currentLine.Value -ge $ProgressStep -and [math]::Floor($currentLine.Value / $ProgressStep) -gt $ProgressCounter.Value) { 
				$ProgressCounter.Value++
				$params = @{
					CurrentLine				= $currentLine.Value
					LinesCount				= $Lines.count
					EstimatedMilliseconds	= $EstimatedMilliseconds.Value
					ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
					Activity				= "Parsing..."
				}
				ReportProgress @params
			}
		}
		#endregion



		#region Old code
		# TODO: Refactor all of these into functions:
		# while ($currentLine.Value -lt $Lines.count) {
		# 	$line = $Lines[$CurrentLine.Value].Trim()
		# 	if ($line[0] -eq "`"") {
		# 		$line			= $line.Trim("`"")
		# 		$skip			= $false
		# 		$propertyName	= ""
		# 		$propertyValue	= ""
		# 		$string			= [ref]$propertyName
		# 		foreach ($char in $line.GetEnumerator()) {
		# 			if ($char -eq "`"") {
		# 				if ($skip) {	# Switch the stringBuilder (to start saving the value to it later)
		# 					$string = [ref]$propertyValue
		# 				}							# Raise the flag
		# 				$skip = -not $skip			# Continue until another match
		# 			} elseif (-not $skip) {
		# 				$string.Value += $char		# Add the char to a new string
		# 			}
		# 		}
		# 		if (-not $currentBlock["properties"][$propertyName]) {
		# 			$currentBlock["properties"][$propertyName] = [ordered]@{}
		# 		}
		# 		$currentBlock["properties"][$propertyName][$propertyCount.ToString()] = $propertyValue
		# 		$propertyCount++

		# 	} elseif ($line[0] -eq "}" -and $line.Length -eq 1) {
		# 		$currentLine.Value++
		# 		$Depth.Value--
		# 		if ($Depth.Value -lt 0) {
		# 			throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
		# 		}
		# 		return $currentBlock
		# 	} elseif ($line -match "$($regex.className)") {
		# 		# Check next line. If it is `{`, start processing a section
		# 		if ($Lines[$CurrentLine.Value + 1].Trim() -eq "{") {
		# 			$CurrentLine.Value += 2
		# 			$Depth.Value++
		# 			$currentKey = $line
		# 			if (-not $currentBlock["classes"][$currentKey]) {
		# 				$currentBlock["classes"][$currentKey] = [ordered]@{}
		# 			}
		# 			$params = @{
		# 				Lines					= $Lines
		# 				CurrentLine				= $currentLine
		# 				LinesFaulty				= $linesFaulty
		# 				Depth					= $Depth
		# 				Regex					= $Regex
		# 				StopWatch				= $StopWatch
		# 				EstimatedMilliseconds	= $EstimatedMilliseconds
		# 			}
		# 			$currentBlock["classes"][$currentKey].Add($classCount.ToString(), $(ParseVmfBlock @params))	# sectionCount is sort of an ID
		# 			# $currentBlock["classes"][$currentKey].Add($classCount.ToString(), "Parsed block placeholder")	# sectionCount is sort of an ID
		# 			$classCount++		# It's needed because any given class can contain multiple classes of the same name
		# 			continue
		# 		} else {
		# 			throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '{' at line $($currentLine.Value + 1)."
		# 		}

		# 	} else {
		# 		if ($line -ne "") {						# Skipping the empty lines
		# 			$linesFaulty.Value++
		# 			Write-Verbose "An unidentified content on line $($currentLine.Value + 1): $_"
		# 			if (-not $PSBoundParameters.ContainsKey('Verbose')) {
		# 				Write-Debug "UNDEFINED (line $($currentLine.Value + 1)): $_"
		# 			}
		# 		}
		# 	}

		# 	$CurrentLine.Value += 1
			
		# 	if ($currentLine.Value -ge 10000 -and $currentLine.Value % 10000 -eq 0) { 
		# 		$elapsedMilliseconds = $StopWatch.Value.ElapsedMilliseconds
		# 		$EstimatedMilliseconds.Value = ($Lines.Count / $currentLine.Value) * $elapsedMilliseconds
		# 	}
		# 	if ($currentLine.Value -ge 1000 -and $currentLine.Value % 1000 -eq 0) { 
		# 		$params = @{
		# 			CurrentLine				= $currentLine.Value
		# 			LinesCount				= $Lines.count
		# 			EstimatedMilliseconds	= $EstimatedMilliseconds.Value
		# 			ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
		# 		}
		# 		ReportProgressVmf @params
		# 	}
		# }
		#endregion
	
		if ($VerbosePreference -ne "SilentlyContinue"){
			ReportStatistics -LinesCount $currentLine.Value -LinesFaulty $linesFaulty.Value
		}
	
		Write-Host  -ForegroundColor DarkYellow 	"Parsing: Complete"
		return $currentBlock
	}