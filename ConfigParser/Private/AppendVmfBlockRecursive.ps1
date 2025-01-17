# TODO: Cleanup

function AppendVmfBlockRecursive {
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

	.PARAMETER Depth
	Indicates the current depth inside a VDF-formatted object (a hashtable). (ref)
#>

	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$StringBuilder,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfSection,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$Depth = [ref]0,
			
		[Parameter(Position = 3,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[ref]$EstimatedLines,

		[Parameter(Position = 5,
		Mandatory = $false)]
		[System.Collections.IDictionary]$LinesOut = [ordered]@{
			properties	= 0;
			classes		= 0;
			lines		= 0
		},
		
		[Parameter(Position = 6,
		Mandatory = $false)]
		[ref]$ProgressCounter = [ref]0,
		
		[Parameter(Position = 7,
		Mandatory = $false)]
		$ProgressStep = 10000
	)

	$tabsKey	= "".PadRight($Depth.Value, "`t")
	
	foreach ($propertyName in $VmfSection["properties"].Keys) {
		foreach ($propertyValue in $VmfSection["properties"][$propertyName]) {
			[void]$StringBuilder.Value.AppendFormat('{0}"{1}" "{2}"{3}', $tabsKey, $propertyName, $propertyValue, "`n")
			$LinesOut["properties"]++
			$LinesOut["lines"]++
		}
	}
		
	foreach ($class in $VmfSection["classes"].Keys) {
		foreach ($classEntry in $VmfSection["classes"][$class]) {
			[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}{0}{3}', $tabsKey, $class, "`n", "{`n")
			$Depth.Value++
			$LinesOut["classes"]++
			$LinesOut["lines"]++
			$params = @{
				StringBuilder			= $StringBuilder
				VmfSection				= $classEntry
				Depth					= $Depth
				StopWatch				= $StopWatch
				EstimatedLines			= $EstimatedLines
				LinesOut				= $LinesOut
				ProgressCounter			= $ProgressCounter
				ProgressStep			= $ProgressStep
			}
			AppendVmfBlockRecursive @params
		}
	}

	$Depth.Value--
	if ($Depth.Value -ge 0) {
		$tabsKey = "".PadRight($Depth.Value, "`t")
		[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', $tabsKey, "}", "`n")
	}

	if ($EstimatedLines.Value -gt 0 -and ($LinesOut["lines"] -gt $ProgressStep -and [math]::Floor($LinesOut["lines"] / $ProgressStep) -gt $ProgressCounter.Value)) {
		$elapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
		$estimatedMilliseconds		= ($EstimatedLines.Value / $LinesOut["lines"]) * $elapsedMilliseconds
		$params = @{
			CurrentLine				= $LinesOut["lines"]
			LinesCount				= $EstimatedLines.Value
			EstimatedMilliseconds	= $estimatedMilliseconds
			ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
			Activity				= "Building..."
		}
		ReportProgressVmf @params
		$ProgressCounter.Value++
	}
}