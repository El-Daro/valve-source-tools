# TODO: Make sure all the LMP contents get copied
#		Some LMP ids are completely new — copy the pointer in this case

using namespace System.Diagnostics

function Copy-LmpIntoVmf {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $true)]
		$CounterLmp,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {
		
		try {

			#region VARIABLES
			$MergesCount["hammerid"]		= 0
			$MergesCount["classname"]		= 0
			$MergesCount["new"]				= 0
			$MergesCount["failed"]			= 0
			$MergesCount["section"]			= 0
			$MergesCount["propsEdited"]		= 0
			$MergesCount["propsSkipped"]	= 0
			$MergesCount["propsTotal"]		= 0
			$progressCounter				= 0
			$progressStep					= $CounterLmp["total"] / 10
			#endregion

:lmpLoop	foreach ($lmpSection in $Lmp["data"].Keys) {
				$idToMatch	= $false
				$matchBy	= ""
				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
					$idToMatch	= $Lmp["data"][$lmpSection]["hammerid"][0]
					$matchBy	= "id"					# Either match by id-hammerid
				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
					$idToMatch	= $Lmp["data"][$lmpSection]["classname"][0]
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
									LmpSection	= $Lmp["data"][$lmpSection]
									MergesCount	= $MergesCount
								}
								Copy-LmpSection @params

								#region In-house copying function (for testing purposes)
								# foreach ($propertyName in $Lmp["data"][$lmpSection].Keys) {
								# 	if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
								# 		if ($vmfClassEntry["properties"][$propertyName] -ne $Lmp["data"][$lmpSection][$propertyName]) {
								# 			$mergesCount["propsEdited"]++
								# 			if ($propertyName.Length -gt 3 -and ($propertyName.SubString(0,2) -eq "On") -or
								# 												($propertyName.SubString(0,3) -eq "Out")) {	
								# 				try {														# See if property name starts with "On"
								# 					if ($vmfClassEntry["classes"].Contains("connections")) {	# And put it in the 'connections' class
								# 						$vmfClassEntry["classes"]["connections"][0]["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
								# 					} else {
								# 						$vmfClassEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
								# 					}
								# 				} catch {
								# 					# Do nothing
								# 					Write-Host -ForegroundColor DarkYellow "Failed to copy connections. Hammerid: $($Lmp["data"][$lmpSection]["hammerid"])"
								# 				}
								# 			} else {
								# 				$vmfClassEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
								# 			}
								# 		} else {
								# 			$mergesCount["propsSkipped"]++
								# 		}
								# 	}
								# }
								#endregion

								break vmfHashLoopH
							}
						}
					}
					if (-not $vmfSectionFound) {
						$MergesCount["new"]++
						# Add a new section to VMF file
						$newBlock = [ordered]@{
							properties = $Lmp["data"][$lmpSection]
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
					$estimatedMilliseconds	= ($CounterLmp["total"] / $MergesCount["section"]) * $elapsedMilliseconds
					$params = @{
						currentLine				= $MergesCount["section"]
						LinesCount				= $CounterLmp["total"]
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