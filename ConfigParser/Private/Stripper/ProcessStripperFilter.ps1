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
		Mandatory = $false)]
		$VisgroupidTable,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$CurrentVisgroup,

		[Parameter(Position = 4,
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 5,
		Mandatory = $true)]
		$CounterStripper,

		[Parameter(Position = 6,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 7,
		Mandatory = $false)]
		$ProcessCounter,

		[Parameter(Position = 8,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Demo
	)
	
	PROCESS {

		$class					= "entity"
		$vgnStripperFiltered	= "Stripper - Filtered"
		if (-not $Vmf["classes"].Contains($class) -or $Vmf["classes"][$class].get_Count() -eq 0) {
			return $false
		}
		$indexesToRemove	= @()
		$vmfClassCount		= $Vmf["classes"][$class].get_Count()
		$progressStep		= [math]::Ceiling($vmfClassCount / 3)
		$vmfCounter			= 0
		$progressCounter	= 0
		foreach ($vmfClassEntry in $Vmf["classes"][$class]) {

			$params = @{
				VmfClassEntry	= $vmfClassEntry
				StripperBlock	= $Filter
			}
			$matchCounter	= ProcessStripperModMatch @params

			if ($matchCounter -eq $Filter["properties"].get_Count()) {
				# $toRemove = $true
				$MergesCount["filter"]++
				$index = $Vmf["classes"][$class].IndexOf($VmfClassEntry)
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
				$indexesToRemove[$i], $($Vmf["classes"][$class].get_Count()))
			if ($PSBoundParameters.ContainsKey('VisgroupidTable') -and
				$PSBoundParameters.ContainsKey('CurrentVisgroup') -and
				$false -ne $CurrentVisgroup -and $Demo.IsPresent) {
				#region Visgroup: Stripper - Filtered
				# NOTE: This will keep the elements and make them hidden by default
				#		They will still exist in the map!
				#		Only do it for demonstration purposes (pass the '-Demo' parameter)
				# Create a new "Stripper - Filtered" visgroup if it doesn't already exist
				if (-not $visgroupidTable.Contains($vgnStripperFiltered)) {
					$params = @{
						VmfSection		= $CurrentVisgroup
						Name			= $vgnStripperFiltered
						Color			= $colorsTable["MediumVioletRed"]
						VisgroupidTable	= $visgroupidTable
					}
					$visgroupStripperMod	= New-VmfVisgroupWrapper @params
				}

				$params = @{
					VmfSection			= $Vmf["classes"][$class][$indexesToRemove[$i]]
					Color				= $colorsTable["MediumVioletRed"]
					VisgroupID			= $visgroupidTable[$vgnStripperFiltered]
					VisgroupShown		= "0"
					VisgroupAutoShown	= "0"
				}
				$success = Add-VmfEditor @params
				#endregion
			} else {
				$Vmf["classes"][$class].RemoveAt($indexesToRemove[$i])
			}
		}
		
		return $true
	}

	END { }
}