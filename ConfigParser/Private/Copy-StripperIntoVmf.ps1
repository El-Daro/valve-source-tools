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

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {
		
		try {

			#region VARIABLES
			$MergesCount["filter"]			= 0
			$MergesCount["add"]				= 0
			$MergesCount["modify"]			= 0
			$MergesCount["filterSkipped"]	= 0
			$MergesCount["addSkipped"]		= 0
			$MergesCount["modifySkipped"]	= 0
			$MergesCount["new"]				= 0
			$MergesCount["failed"]			= 0
			$MergesCount["section"]			= 0
			$MergesCount["propsEdited"]		= 0
			$MergesCount["propsSkipped"]	= 0
			$MergesCount["propsTotal"]		= 0
			$progressCounter				= 0
			$progressStep					= $CounterStripper["total"] / 10
			#endregion

			if ($Stripper["modes"]["filter"].Count -gt 0) {
:filterLoop		foreach ($filter in $Stripper["modes"]["filter"]) {
					$filterProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Filter			= $filter
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
					}
					$filterProcessed = ProcessStripperFilter @params
					if ($filterProcessed) {
						$MergesCount["filter"]++
					} else {
						$MergesCount["failed"]++
					}
				}
			}

			if ($Stripper["modes"]["add"].Count -gt 0) {
:addLoop		foreach ($add in $Stripper["modes"]["add"]) {
					$addProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Add				= $add
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
					}
					$addProcessed = ProcessStripperAdd @params
					# $MergesCount["add"]++
					# $MergesCount["propsNew"] += $add["properties"].Count
					# $Vmf["classes"]["entity"].Add($add)

					if (-not $addProcessed) {
						$MergesCount["failed"]++
					}
				}
			}
			# TEMP
			return $true

			# Different approach to modifies
			if ($Stripper["modes"]["modify"].Count -gt 0) {
:modLoop		foreach ($modify in $Stripper["modes"]["modify"]) {
					$modifyProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Modify			= $modify
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
					}
					$modifyProcessed = ProcessStripperModify @params
					if ($modifyProcessed) {
						$MergesCount["modify"]++
					} else {
						$MergesCount["failed"]++
					}
				}
			}
			return $true

:lmpLoop	foreach ($lmpSection in $Stripper["data"].Keys) {
				$idToMatch	= $false
				$matchBy	= ""
				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
					$idToMatch	= $Stripper["data"][$lmpSection]["hammerid"][0]
					$matchBy	= "id"					# Either match by id-hammerid
				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
					$idToMatch	= $Stripper["data"][$lmpSection]["classname"][0]
					$matchBy	= "classname"			# Or by a classname
				} else {
					$MergesCount["failed"]++			# You're not supposed to be here, but just in case
					Write-Host -ForegroundColor DarkYellow "This is an error"
					Write-Host $lmpSection
				}
				if ($idToMatch) {
					$vmfSectionFound = $false
:vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfListLoopH			foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {
							if ($vmfClassEntry["properties"].Contains($matchBy) -and
								$idToMatch -eq $vmfClassEntry["properties"][$matchBy][0]) {
								$vmfSectionFound = $true
								if ($matchBy -eq "id") {
									$MergesCount["hammerid"]++
								} else {
									$MergesCount["classname"]++
								}
								$params = @{
									VmfSection	= $vmfClassEntry
									StripperSection	= $Stripper["data"][$lmpSection]
									MergesCount	= $MergesCount
								}
								Copy-StripperSection @params

								break vmfHashLoopH
							}
						}
					}
					if (-not $vmfSectionFound) {
						$MergesCount["new"]++
						# Add a new section to VMF file
						$newBlock = [ordered]@{
							properties = $Stripper["data"][$lmpSection]
							classes    = [ordered]@{}
						}
						$MergesCount["propsNew"] += $newBlock["properties"].Count
						$Vmf["classes"]["entity"].Add($newBlock)
					}
				}
				$MergesCount["section"]++

				if ($MergesCount["section"] -ge $progressStep -and [math]::Floor($MergesCount["section"] / $progressStep) -gt $progressCounter) { 
					$progressCounter++
					$elapsedMilliseconds	= $sw.ElapsedMilliseconds
					$estimatedMilliseconds	= ($CounterStripper["total"] / $MergesCount["section"]) * $elapsedMilliseconds
					$params = @{
						currentLine				= $MergesCount["section"]
						LinesCount				= $CounterStripper["total"]
						EstimatedMilliseconds	= $estimatedMilliseconds
						ElapsedMilliseconds		= $sw.ElapsedMilliseconds
						Activity				= "Merging..."
					}
					ReportProgress @params
				}
			}

			$MergesCount["propsTotal"] = $MergesCount["propsEdited"] + $MergesCount["propsSkipped"] + $MergesCount["propsNew"]
			return $true

		} catch {
			# Pay attention to errors
			return $false
		} finally {
			
		}
	}

	END { }
}