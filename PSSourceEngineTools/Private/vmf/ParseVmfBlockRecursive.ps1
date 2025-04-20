# NOTE: Performance considerations
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
			$string			= [ref]$sbPropName
			foreach ($char in $line.GetEnumerator()) {
				if ($char -eq "`"") {
					if ($skip) {	# Switch the stringBuilder (to start saving the value to it later)
						$string = [ref]$sbPropValue
					}							# Raise the flag
					$skip = -not $skip			# Continue until another match
				} elseif (-not $skip) {
					[void]$string.Value.Append($char)
				}
			}
			$propertyName	= $sbPropName.ToString()
			$propertyValue	= $sbPropValue.ToString()
			if (-not $currentBlock["properties"].Contains($propertyName)) {
				$currentBlock["properties"][$propertyName] = [System.Collections.Generic.List[string]]::new()

			}
			$currentBlock["properties"][$propertyName].Add($propertyValue)
			$propertyCount++

		} elseif ($line[0] -eq "}") {
			$currentLine.Value++
			$Depth.Value--
			if ($Depth.Value -lt 0) {
				throw [System.FormatException] "$($MyInvocation.MyCommand): Unexpected '}' at line $($currentLine.Value)."
			}
			return $currentBlock
		} else {
			$CurrentLine.Value += 2
			$Depth.Value++
			if (-not $currentBlock["classes"].Contains($line)) {
				if ($line -eq "entity" -or $line -eq "solid") {
					$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new(8000)
				} else {
					$currentBlock["classes"][$line] = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
				}
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
			$classCount++		# It's needed because any given class can contain multiple classes of the same name
			continue
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

	if ($VerbosePreference -ne "SilentlyContinue"){
		ReportStatistics -LinesCount $currentLine.Value -LinesFaulty $linesFaulty.Value
	}

	Write-Host  -ForegroundColor DarkYellow 	"Parsing: Complete"
	return $currentBlock
}