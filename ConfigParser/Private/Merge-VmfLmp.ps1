using namespace System.Diagnostics

function Merge-VmfLmp {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		$lmpHammerIdOffset	= 9
		$lmpClassnameOffset	= 10
		
		try {

			$sw = [Stopwatch]::StartNew()

			# 1. Analyze the lmp hashtable
			#region Analyzing LMP
			$params = @{
				Lmp					= $Lmp
				LmpHammerIdOffset	= $lmpHammerIdOffset
				LmpClassnameOffset	= $lmpClassnameOffset
			}
			$counterLmp = EstimateMergerInputLmp @params
			#endregion

			# 2. Merge the two hashtables
			#region Merging LMP into VMF
			# TODO: Make sure all the LMP contents get copied
			# TODO: Refactor into its own function
			$mergesCount		= @{
				hammerid		= 0
				classname		= 0
				failed			= 0
				section			= 0
				propsEdited		= 0
				propsSkipped	= 0
				propsTotal		= 0
			}
			# $progressCounter	= 0
			# $progressStep		= $counterLmp["total"] / 10

			$params	= @{
				Vmf				= $Vmf
				Lmp				= $Lmp
				MergesCount		= $mergesCount
				CounterLmp		= $counterLmp
			}
			$copied = Copy-LmpIntoVmf @params

<#
			# $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"]
# :lmpLoop	foreach ($lmpSection in $Lmp["data"].Keys) {
# 				$idToMatch	= $false
# 				$matchBy	= ""
# 				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
# 					$idToMatch	= $Lmp["data"][$lmpSection]["hammerid"][0]
# 					$matchBy	= "id"					# Either match by id-hammerid
# 				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
# 					$idToMatch	= $Lmp["data"][$lmpSection]["classname"][0]
# 					$matchBy	= "classname"			# Or by a classname
# 				} else {
# 					$mergesCount["failed"]++
# 					Write-Host -ForegroundColor DarkYellow "This is an error"
# 					Write-Host $lmpSection
# 				}
# 				if ($idToMatch) {
# :vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
# :vmfListLoopH			foreach ($classEntry in $Vmf["classes"][$vmfClass]) {
# 							if ($idToMatch -eq $classEntry["properties"][$matchBy][0]) {
# 								if ($matchBy -eq "id") {
# 									$mergesCount["hammerid"]++
# 								} else {
# 									$mergesCount["classname"]++
# 								}
# 								$params = @{
# 									VmfSection	= $classEntry
# 									LmpSection	= $Lmp["data"][$lmpSection]
# 									MergesCount	= $mergesCount
# 									# PropsSkipped = [ref]$propsSkipped
# 									LogFile		= $LogFile
# 									Silent		= $Silent.IsPresent
# 								}
# 								Copy-LmpSection @params

# 								#region In-house copying function (for testing)
# 								# foreach ($propertyName in $Lmp["data"][$lmpSection].Keys) {
# 								# 	if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
# 								# 		if ($classEntry["properties"][$propertyName] -ne $Lmp["data"][$lmpSection][$propertyName]) {
# 								# 			$mergesCount["propsEdited"]++
# 								# 			if ($propertyName.Length -gt 3 -and ($propertyName.SubString(0,2) -eq "On") -or
# 								# 												($propertyName.SubString(0,3) -eq "Out")) {	
# 								# 				try {														# See if property name starts with "On"
# 								# 					if ($classEntry["classes"].Contains("connections")) {	# And put it in the 'connections' class
# 								# 						$classEntry["classes"]["connections"][0]["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
# 								# 					} else {
# 								# 						$classEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
# 								# 					}
# 								# 				} catch {
# 								# 					# Do nothing
# 								# 					Write-Host -ForegroundColor DarkYellow "Failed to copy connections. Hammerid: $($Lmp["data"][$lmpSection]["hammerid"])"
# 								# 				}
# 								# 			} else {
# 								# 				$classEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
# 								# 			}
# 								# 		} else {
# 								# 			$mergesCount["propsSkipped"]++
# 								# 		}
# 								# 	}
# 								# }
# 								#endregion

# 								break vmfHashLoopH
# 							}
# 						}
# 					}
# 				}
# 				$mergesCount["section"]++

# 				if ($mergesCount["section"] -ge $progressStep -and [math]::Floor($mergesCount["section"] / $progressStep) -gt $progressCounter) { 
# 					$progressCounter++
# 					$elapsedMilliseconds	= $sw.ElapsedMilliseconds
# 					$estimatedMilliseconds	= ($counterLmp["total"] / $mergesCount["section"]) * $elapsedMilliseconds
# 					$params = @{
# 						currentLine				= $mergesCount["section"]
# 						LinesCount				= $counterLmp["total"]
# 						EstimatedMilliseconds	= $estimatedMilliseconds
# 						ElapsedMilliseconds		= $sw.ElapsedMilliseconds
# 						Activity				= "Merging..."
# 					}
# 					ReportProgress @params
# 				}
# 			}
#>

			$mergesCount["propsTotal"] = $mergesCount["propsEdited"] + $mergesCount["propsSkipped"]
			if (-not $copied) {
				Throw $_.Exception
			}
			#endregion
		} catch {
			# Pay attention to errors
		} finally {
			$sw.Stop()

			#region Logging
			if (-not $Silent.IsPresent) {
				$sectionsPerSecond = ($mergesCount["section"] / $sw.ElapsedMilliseconds) * 1000
				$propsPerSecond = ($mergesCount["propsTotal"] / $sw.ElapsedMilliseconds) * 1000
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog 							-Value "`nVMF-LMP | Merging: Complete"														-Path $LogFile -OneLine
				OutLog -Property "Input hammerids"		-Value $("{0} / {1}" -f $counterLmp["hammerid"], $counterLmp["total"])				-Path $LogFile
				OutLog -Property "Input classnames"		-Value $("{0} / {1}" -f $counterLmp["classname"], $counterLmp["total"])				-Path $LogFile
				if ($counterLmp["unknown"] -gt 0) {
					OutLog -Property "Unknown sections"	-Value $("{0} / {1}" -f $counterLmp["unknown"], $counterLmp["total"])				-Path $LogFile
				}
				OutLog -Property "Merged hammerids"		-Value $("{0} / {1}" -f $mergesCount["hammerid"], $counterLmp["total"])				-Path $LogFile
				OutLog -Property "Merged classnames"	-Value $("{0} / {1}" -f $mergesCount["classname"], $counterLmp["total"])			-Path $LogFile
				if ($mergesCount["failed"] -gt 0) {
					OutLog -Property "Matches failed"	-Value $("{0} / {1}" -f $mergesCount["failed"], $counterLmp["total"])				-Path $LogFile
				}
				OutLog -Property "Properties edited"	-Value $("{0} / {1}" -f $mergesCount["propsEdited"], $mergesCount["propsTotal"])	-Path $LogFile
				OutLog -Property "Properties skipped"	-Value $("{0} / {1}" -f $mergesCount["propsSkipped"], $mergesCount["propsTotal"])	-Path $LogFile
				OutLog -Property "Elapsed time"			-Value $timeFormatted									-Path $LogFile
				OutLog -Property "Speed"		-Value $("{0:n0} sections per second" -f $sectionsPerSecond)	-Path $LogFile
				OutLog -Property "Speed"		-Value $("{0:n0} properties per second" -f $propsPerSecond)		-Path $LogFile
			}
			#endregion
		}

		return $Vmf
	}

	END { }
}