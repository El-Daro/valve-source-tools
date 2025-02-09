# TODO: IMPROVE
#		- Consider recursive structure

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

:mainL	foreach ($vmfClass in $Vmf["classes"].Keys) {
			$indexesToRemove	= @()
			$vmfClassCount		= $Vmf["classes"][$vmfClass].get_Count()
			$progressStep		= [math]::Ceiling($vmfClassCount / 5)
			$vmfCounter			= 0
			$progressCounter	= 0
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
						# The new code for the matches
						if ($value.Length -gt 2 -and $value[0] -eq "/" -and $value[$value.Length - 1] -eq "/") {
							$stripperValueRegex = $value.SubString(1, $value.Length - 2) 
							if ($vmfClassEntry["properties"].Contains($key)) {
								try {
									foreach ($vmfPropValue in $vmfClassEntry["properties"][$key]) {
										if ($vmfPropValue -match $stripperValueRegex) {
											$matchCounter++
											break
										}
									}
								} catch {
									Write-Debug "$($MyInvocation.MyCommand):  Failed to do a regex check"
								}
							} else {
								break stripperMainL
							}
						} else {

							# The original code for the matches
							if ($vmfClassEntry["properties"].Contains($key) -and
								$vmfClassEntry["properties"][$key].Contains($value)) {
								$matchCounter++	
							# $vmfSectionFound = $true
							} else {
								break stripperMainL
							}
						}
					}
				}
				if ($matchCounter -eq $Filter["properties"].Count) {
					# $toRemove = $true
					$MergesCount["filter"]++
					$index = $Vmf["classes"][$vmfClass].IndexOf($VmfClassEntry)
					$indexesToRemove += $index
				}

				#region Time estimation
				if ($VmfClassCount -gt 1 -and
						$vmfCounter -ge $progressStep -and [math]::Floor($vmfCounter / $progressStep) -gt $progressCounter) { 
					$progressCounter++
					$elapsedMilliseconds	= $StopWatch.Value.ElapsedMilliseconds
					$estimatedMilliseconds	= ($VmfClassCount / $vmfCounter) * $elapsedMilliseconds
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
					$indexesToRemove[$i], $($Vmf["classes"][$vmfClass].Count))
				$Vmf["classes"][$vmfClass].RemoveAt($indexesToRemove[$i])
			}
		}
		
		return $true
	}

	END { }
}