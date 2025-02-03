function AppendStripperBlock {
<#
	.SYNOPSIS
	Converts a single block of a hashtable to a stripper .cfg formatted string

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for stripper .cfg files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER StringBuilder
	StringBuilder object contains the whole stripper .cfg formatted string that needs to be modified. (ref)

	.PARAMETER StripperSection
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing key-value pairs or other blocks of the stripper .cfg format.

	.PARAMETER Depth
	Indicates the current depth inside a stripper .cfg formatted object (a hashtable). (ref)
#>

	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$StringBuilder,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$StripperSection,
		
		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$Depth = [ref]0,
			
		[Parameter(Position = 4,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 5,
		Mandatory = $false)]
		$EstimatedOutput,

		[Parameter(Position = 6,
		Mandatory = $false)]
		[System.Collections.IDictionary]$LinesOut = [ordered]@{
			filter	= 0;
			add		= 0;
			modify	= 0;
			lines	= 0
		},
		
		[Parameter(Position = 7,
		Mandatory = $false)]
		[ref]$ProgressCounter = [ref]0,
		
		[Parameter(Position = 8,
		Mandatory = $false)]
		$ProgressStep = 10000
	)

	$tabsKey	= "".PadRight($Depth.Value, "`t")
	
	foreach ($propertyName in $StripperSection["properties"].Keys) {
		foreach ($propertyValue in $StripperSection["properties"][$propertyName]) {
			[void]$StringBuilder.Value.AppendFormat('{0}"{1}" "{2}"{3}', $tabsKey, $propertyName, $propertyValue, "`n")
			$LinesOut["properties"]++
			$LinesOut["lines"]++
		}
	}
		
	foreach ($mode in $StripperSection["modes"].Keys) {
		if ($StripperSection["modes"][$mode].Count -eq 0) {
			continue
		}
		$LinesOut[$Mode] = 0
		[void]$StringBuilder.Value.AppendFormat('{0}{1}:{2}', $tabsKey, $mode, "`n")
		$LinesOut["lines"]++
		foreach ($modeEntry in $StripperSection["modes"][$mode]) {
			[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', $tabsKey, "{", "`n")
			$Depth.Value++
			$LinesOut["modes"]++
			$LinesOut["lines"]++
			$params = @{
				StringBuilder			= $StringBuilder
				StripperSection			= $modeEntry
				Depth					= $Depth
				StopWatch				= $StopWatch
				LinesOut				= $LinesOut
				EstimatedOutput			= $EstimatedOutput
				ProgressCounter			= $ProgressCounter
				ProgressStep			= $ProgressStep
			}
			AppendStripperBlock @params
		}
	}

	$Depth.Value--
	if ($Depth.Value -ge 0) {
		$tabsKey = "".PadRight($Depth.Value, "`t")
		[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', $tabsKey, "}", "`n")
	}

	if ($EstimatedOutput["lines"] -gt $ProgressStep -and
			$EstimatedOutput["lines"] -gt 10000 -and
			($LinesOut["lines"] -gt $ProgressStep -and
			[math]::Floor($LinesOut["lines"] / $ProgressStep) -gt $ProgressCounter.Value)) {
		$elapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
		$estimatedMilliseconds		= ($EstimatedOutput["lines"] / $LinesOut["lines"]) * $elapsedMilliseconds
		$params = @{
			CurrentLine				= $LinesOut["lines"]
			LinesCount				= $EstimatedOutput["lines"]
			EstimatedMilliseconds	= $estimatedMilliseconds
			ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
			Activity				= "Building..."
		}
		ReportProgress @params
		$ProgressCounter.Value++
	}
}