function ParseVmfBlockIter {

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
		Mandatory = $false)]
		[ref]$StopWatch
	)
	
	$currentBlock			= [ordered]@{
		properties			= [ordered]@{};
		classes				= [ordered]@{}
	}
	# $stackBlocks			= [System.Collections.Generic.Stack[ordered]]::new()
	$stackBlocks			= [Collections.Generic.Stack[Collections.Specialized.OrderedDictionary]]::new()
	$estimatedMilliseconds	= 0
	$progressCounter		= 0
	$progressStep			= [math]::Ceiling($Lines.Count / 50)

	while ($currentLine.Value -lt $Lines.count) {
	
		$line = $Lines[$CurrentLine.Value].Trim()
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
			$CurrentLine.Value += 1				# Jump over the open bracket
			if (-not $currentBlock["classes"].Contains($line)) {
				$currentBlock["classes"][$line] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
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
		
		$CurrentLine.Value += 1

		if ($currentLine.Value -ge $progressStep -and [math]::Floor($currentLine.Value / $progressStep) -gt $progressCounter) { 
			$progressCounter++
			$elapsedMilliseconds = $StopWatch.Value.ElapsedMilliseconds
			$estimatedMilliseconds = ($Lines.Count / $currentLine.Value) * $elapsedMilliseconds
			$params = @{
				CurrentLine				= $currentLine.Value
				LinesCount				= $Lines.count
				EstimatedMilliseconds	= $estimatedMilliseconds
				ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
				Activity				= "Parsing..."
			}
			ReportProgress @params
		}

	}

	return $currentBlock
}