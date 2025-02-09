using namespace System.Diagnostics

function Copy-StripperIntoVmf {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Stripper,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $true)]
		$CounterStripper,

		[Parameter(Position = 3,
		Mandatory = $true)]
		[ref]$StopWatch,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {
		
		try {

			#region VARIABLES
			$MergesCount["filter"]			= 0			# +
			$MergesCount["add"]				= 0			# +
			$MergesCount["modify"]			= 0			# +
			$MergesCount["modifyReplaced"]	= 0			# +
			$MergesCount["modifyDeleted"]	= 0			# +
			$MergesCount["modifyInserted"]	= 0			# +

			$MergesCount["filterSkipped"]	= 0			# +
			$MergesCount["addSkipped"]		= 0			# +
			$MergesCount["modifySkipped"]	= 0			# +

			$MergesCount["new"]				= 0			# -
			$MergesCount["addFailed"]		= 0			# +
			$MergesCount["modifyFailed"]	= 0			# +
			$MergesCount["failed"]			= 0			# +
			$MergesCount["section"]			= 0			# - (*)

			$MergesCount["propsNew"]		= 0			# + (?)
			$MergesCount["propsEdited"]		= 0			# +
			$MergesCount["propsDeleted"]	= 0			# + (?)
			$MergesCount["propsSkipped"]	= 0			# -
			$MergesCount["propsTotal"]		= 0
			$progressCounter				= 0
			$progressStep					= $CounterStripper["total"] / 10
			#endregion

			if ($Stripper["modes"]["filter"].get_Count() -gt 0) {
				$filterCounter	= @{
					total		= $Stripper["modes"]["filter"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:filterLoop		foreach ($filter in $Stripper["modes"]["filter"]) {
					$filterProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Filter			= $filter
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $filterCounter
					}
					$filterProcessed = ProcessStripperFilter @params
					$filterCounter["counter"]++
					# if (-not $filterProcessed) {
					# 	$MergesCount["failed"]++
					# }
				}
				$sw.Stop()
			}

			if ($Stripper["modes"]["add"].get_Count() -gt 0) {
				$addCounter	= @{
					total		= $Stripper["modes"]["add"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:addLoop		foreach ($add in $Stripper["modes"]["add"]) {
					$addProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Add				= $add
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $addCounter
					}
					# Adding is O(1), so we don't need to create progress bar. Params passed for future use
					$addProcessed = ProcessStripperAdd @params
					$addCounter["counter"]++
					if (-not $addProcessed) {
						$MergesCount["addFailed"]++
					}
				}
				$sw.Stop()
			}

			# Different approach to modifies
			if ($Stripper["modes"]["modify"].get_Count() -gt 0) {
				$modifyCounter	= @{
					total		= $Stripper["modes"]["modify"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:modLoop		foreach ($modify in $Stripper["modes"]["modify"]) {
					$modifyProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Modify			= $modify
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $modifyCounter
					}
					$modifyProcessed = ProcessStripperModify @params
					$modifyCounter["counter"]++
					if (-not $modifyProcessed) {
						$MergesCount["modifyFailed"]++
					}
				}
				$sw.Stop()
			}

			#region LMP code
# :lmpLoop	foreach ($lmpSection in $Stripper["data"].Keys) {
# 				$idToMatch	= $false
# 				$matchBy	= ""
# 				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
# 					$idToMatch	= $Stripper["data"][$lmpSection]["hammerid"][0]
# 					$matchBy	= "id"					# Either match by id-hammerid
# 				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
# 					$idToMatch	= $Stripper["data"][$lmpSection]["classname"][0]
# 					$matchBy	= "classname"			# Or by a classname
# 				} else {
# 					$MergesCount["failed"]++			# You're not supposed to be here, but just in case
# 					Write-Host -ForegroundColor DarkYellow "This is an error"
# 					Write-Host $lmpSection
# 				}
# 				if ($idToMatch) {
# 					$vmfSectionFound = $false
# :vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
# :vmfListLoopH			foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {
# 							if ($vmfClassEntry["properties"].Contains($matchBy) -and
# 								$idToMatch -eq $vmfClassEntry["properties"][$matchBy][0]) {
# 								$vmfSectionFound = $true
# 								if ($matchBy -eq "id") {
# 									$MergesCount["hammerid"]++
# 								} else {
# 									$MergesCount["classname"]++
# 								}
# 								$params = @{
# 									VmfSection	= $vmfClassEntry
# 									StripperSection	= $Stripper["data"][$lmpSection]
# 									MergesCount	= $MergesCount
# 								}
# 								Copy-StripperSection @params

# 								break vmfHashLoopH
# 							}
# 						}
# 					}
# 					if (-not $vmfSectionFound) {
# 						$MergesCount["new"]++
# 						# Add a new section to VMF file
# 						$newBlock = [ordered]@{
# 							properties = $Stripper["data"][$lmpSection]
# 							classes    = [ordered]@{}
# 						}
# 						$MergesCount["propsNew"] += $newBlock["properties"].Count
# 						$Vmf["classes"]["entity"].Add($newBlock)
# 					}
# 				}
# 				$MergesCount["section"]++

# 				if ($MergesCount["section"] -ge $progressStep -and [math]::Floor($MergesCount["section"] / $progressStep) -gt $progressCounter) { 
# 					$progressCounter++
# 					$elapsedMilliseconds	= $sw.ElapsedMilliseconds
# 					$estimatedMilliseconds	= ($CounterStripper["total"] / $MergesCount["section"]) * $elapsedMilliseconds
# 					$params = @{
# 						currentLine				= $MergesCount["section"]
# 						LinesCount				= $CounterStripper["total"]
# 						EstimatedMilliseconds	= $estimatedMilliseconds
# 						ElapsedMilliseconds		= $sw.ElapsedMilliseconds
# 						Activity				= "Merging..."
# 					}
# 					ReportProgress @params
# 				}
# 			}
			#endregion
			$MergesCount["failed"]		= $MergesCount["addFailed"] + $MergesCount["modifyFailed"]
			$MergesCount["propsTotal"]	= $MergesCount["propsEdited"] + $MergesCount["propsSkipped"] + $MergesCount["propsNew"] + $MergesCount["propsDeleted"]
			return $true

		} catch {
			# Pay attention to errors
			return $false
		} finally {
			
		}
	}

	END { }
}