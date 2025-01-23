# NOTE: This one turned out to be a disaster
#		A significantly (from 30% up to 1000%) worsened performance

# TODO: Try to have another go and eliminate the problem

function AppendVmfBlockIter {
<#
	.SYNOPSIS
	Converts a single block of a hashtable to a VDF-formatted string

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vmf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER StringBuilder
	StringBuilder object contains the whole .vmf formatted string that needs to be modified. (ref)

	.PARAMETER VmfSection
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing key-value pairs or other blocks of the .vmf format.
#>

	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$StringBuilder,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfSection,
			
		[Parameter(Position = 2,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$EstimatedLines
	)

	#region VARIABLES
	$stackBlocks		= [System.Collections.Generic.Stack[ordered]]::new()
	$counter			= 0
	$counterList		= 0
	$printProperties	= $True
	$currentBlock		= $VmfSection
	$stackBlocks.Push([ordered]@{
		Block			= $VmfSection;
		Counter			= $counter;
		CounterList		= $counterList
		PrintProperties	= $printProperties
	})
	$linesOut = [ordered]@{
		properties		= 0;
		classes			= 0;
		lines			= 0
	}
	$depth				= 0
	$progressCounter	= 0
	$progressStep		= $EstimatedLines / 50
	$skip				= $false
	$tabsKey			= "".PadRight($Depth, "`t")
	#endregion
	
	while ($stackBlocks.Count -gt 0) {
		if ($printProperties) {
			foreach($propertyName in $currentBlock["properties"].Keys) {
				# Counting properties
				foreach ($propertyEntry in $currentBlock["properties"][$propertyName]) {	# KEY-VALUE
					[void]$StringBuilder.Value.AppendFormat('{0}"{1}" "{2}"{3}', $tabsKey, $propertyName, $propertyEntry, "`n")
					$linesOut["properties"]++
					$linesOut["lines"]++
				}
			}
			# $printProperties = $False
		}

:cLoop	while ($counter -lt $currentBlock["classes"].Count) {
			$skip = $False
			$className = ($currentBlock["classes"] | Select-Object -Property Keys).Keys[$counter]
			while ($counterList -lt $currentBlock["classes"][$counter].Count) {
				[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}{0}{3}', $tabsKey, $className, "`n", "{`n")
				$Depth++
				$tabsKey			= "".PadRight($Depth, "`t")
				$linesOut["classes"]++
				$linesOut["lines"]++

				$stackBlocks.Push([ordered]@{
					Block			= $currentBlock
					Counter			= $counter
					CounterList		= $counterList
					PrintProperties	= $False
				})
				$currentBlock		= $currentBlock["classes"][$counter][$counterList]
				$counter			= 0
				$counterList		= 0
				$printProperties	= $True
				break cLoop
			}
			$counter++
			$counterList = 0
			$skip = $True
		}

		if ($EstimatedLines -gt 0 -and ($linesOut["lines"] -gt $progressStep -and [math]::Floor($linesOut["lines"] / $progressStep) -gt $progressCounter)) {
			$elapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
			$estimatedMilliseconds		= ($EstimatedLines / $linesOut["lines"]) * $elapsedMilliseconds
			$params = @{
				CurrentLine				= $linesOut["lines"]
				LinesCount				= $EstimatedLines
				EstimatedMilliseconds	= $estimatedMilliseconds
				ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
				Activity				= "Building..."
			}
			ReportProgress @params
			$progressCounter++
		}

		if ($skip) {
			$Depth--
			if ($Depth -ge 0) {
				$tabsKey = "".PadRight($Depth, "`t")
				[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', $tabsKey, "}", "`n")
			} 

			$block				= $stackBlocks.Pop()
			$currentBlock		= $block["Block"]
			$counter			= $block["Counter"]
			$counterList		= $block["CounterList"] + 1
			$printProperties	= $block["PrintProperties"]
		} else {
			$skip = $True
		}
	}
}