# TODO: Consider recursive structure
# TODO: Implement regex matching
# TODO: REFACTOR
#		- Incorporate the filter loop inside this function. Should save some time
#		REASONING: We don't need to remove the same element twice. One match = add&skip

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
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		#region VARIABLES
		
		#endregion

		# foreach ($property in $Filter["properties"].Keys) {
			# 'property' is 'classname'
			# $Filter["properties"][$property] is func_playerinfected_clip
			# PROCESS FILTERS
			
			# $vmfSectionFound = $false
:mainL	foreach ($vmfClass in $Vmf["classes"].Keys) {
			$indexesRemove = @()
:vmfClassL	foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {
				# $toRemove = $false
				$matchCounter = 0
:stripperMainL	foreach ($stripperProp in $Filter["properties"].Keys) {
					if ($stripperProp -eq "hammerid") {
						$key = "id"
					} else {
						$key = $stripperProp
					}
					$stripperValues = $Filter["properties"][$stripperProp]
					foreach ($value in $stripperValues) {
						if ($vmfClassEntry["properties"].Contains($key) -and
							$vmfClassEntry["properties"][$key].Contains($value)) {
							$matchCounter++	
						# $vmfSectionFound = $true
						} else {
							break stripperMainL
						}
					}
				}
				if ($matchCounter -eq $Filter["properties"].Count) {
					# $toRemove = $true
					$MergesCount["filter"]++
					$index = $Vmf["classes"][$vmfClass].IndexOf($VmfClassEntry)
					$indexesRemove += $index
				}
			}
			for ($i = $indexesRemove.Count - 1; $i -ge 0; $i--) {
				Write-Host -ForegroundColor DarkYellow $("Removing at {0} / {1}" -f
					$indexesRemove[$i], $($Vmf["classes"][$vmfClass].Count))
				$Vmf["classes"][$vmfClass].RemoveAt($indexesRemove[$i])
			}
			# foreach ($index in $indexesRemove) {
			# 	Write-Host -ForegroundColor DarkYellow "Removing at $index out of $($Vmf["classes"][$vmfClass].Count)"
			# 	$Vmf["classes"][$vmfClass].RemoveAt($index)
			# }
		}
			# if (-not $vmfSectionFound) {
			# 	$MergesCount["new"]++
			# 	# Add a new section to VMF file
			# 	$newBlock = [ordered]@{
			# 		properties = $Stripper["data"][$lmpSection]
			# 		classes    = [ordered]@{}
			# 	}
			# 	$MergesCount["propsNew"] += $newBlock["properties"].Count
			# 	$Vmf["classes"]["entity"].Add($newBlock)
			# }
			# $MergesCount["section"]++

			# if ($MergesCount["section"] -ge $progressStep -and [math]::Floor($MergesCount["section"] / $progressStep) -gt $progressCounter) { 
			# 	$progressCounter++
			# 	$elapsedMilliseconds	= $sw.ElapsedMilliseconds
			# 	$estimatedMilliseconds	= ($CounterStripper["total"] / $MergesCount["section"]) * $elapsedMilliseconds
			# 	$params = @{
			# 		currentLine				= $MergesCount["section"]
			# 		LinesCount				= $CounterStripper["total"]
			# 		EstimatedMilliseconds	= $estimatedMilliseconds
			# 		ElapsedMilliseconds		= $sw.ElapsedMilliseconds
			# 		Activity				= "Merging..."
			# 	}
			# 	ReportProgress @params
			# }
		# }

		# $MergesCount["propsTotal"] = $MergesCount["propsEdited"] + $MergesCount["propsSkipped"] + $MergesCount["propsNew"]
		return $true
	}

	END { }
}