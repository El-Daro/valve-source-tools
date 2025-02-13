# TODO: IMPROVE
#		- Consider recursive structure
# DONE:
#		- Utilize the ProcessStripperModMatch function
#
# TODO: REFACTOR
#		- Incorporate the filter loop inside this function. Should save some time
#		REASONING: We don't need to remove the same element twice. One match = add&skip
#		OCCURENCE: Very rare

using namespace System.Diagnostics

function ProcessStripperFilter {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Filter,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $true)]
		$CounterStripper,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 5,
		Mandatory = $false)]
		$ProcessCounter,

		[Parameter(Position = 6,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

:main	foreach ($vmfClass in $Vmf["classes"].Keys) {
			$indexesToRemove	= @()
			$vmfClassCount		= $Vmf["classes"][$vmfClass].get_Count()
			$progressStep		= [math]::Ceiling($vmfClassCount / 3)
			$vmfCounter			= 0
			$progressCounter	= 0
:vmfClass	foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {

				$params = @{
					VmfClassEntry	= $vmfClassEntry
					StripperBlock	= $Filter
				}
				$matchCounter	= ProcessStripperModMatch @params

				if ($matchCounter -eq $Filter["properties"].get_Count()) {
					# $toRemove = $true
					$MergesCount["filter"]++
					$index = $Vmf["classes"][$vmfClass].IndexOf($VmfClassEntry)
					$indexesToRemove += $index
				}

				#region Time estimation
				if ($VmfClassCount -gt 1000 -and
						$vmfCounter -ge $progressStep -and [math]::Floor($vmfCounter / $progressStep) -gt $progressCounter) { 
					$progressCounter++
					$elapsedMilliseconds	= $StopWatch.Value.ElapsedMilliseconds
					$estimatedMilliseconds	= $elapsedMilliseconds *
						(($VmfClassCount * $ProcessCounter["total"]) / ($vmfCounter + $VmfClassCount * $ProcessCounter["counter"]))
					$params = @{
						currentLine				= $vmfCounter
						LinesCount				= $VmfClassCount
						EstimatedMilliseconds	= $estimatedMilliseconds
						ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
						Activity				= $("Stripper: Merging filter {0} / {1} ..." -f
														$ProcessCounter["counter"], $ProcessCounter["total"])
					}
					ReportProgress @params
				}
				#endregion
				$vmfCounter++

			}
			if ($indexesToRemove.Count -eq 0) {
				$MergesCount["filterSkipped"]++
			}
			for ($i = $indexesToRemove.Count - 1; $i -ge 0; $i--) {
				Write-Debug $("Filter: Removing at {0} / {1}" -f
					$indexesToRemove[$i], $($Vmf["classes"][$vmfClass].get_Count()))
				$Vmf["classes"][$vmfClass].RemoveAt($indexesToRemove[$i])
			}
		}
		
		return $true
	}

	END { }
}