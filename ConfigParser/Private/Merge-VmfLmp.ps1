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

		$lmpHammerIdOffset = 9
		$lmpClassnameOffset = 10

		try {

			# 1. Hard-copy VMF (not entirely hard copy, but okay)
			# $vmfMerged = [ordered]@{ }
			# foreach ($vmfSection in $Vmf.Keys) {
			# 	$vmfMerged[$vmfSection] = $Vmf[$vmfSection]
			# }	

			# 2. Analyze the lmp hashtable
			$sw = [Stopwatch]::StartNew()
			$counterHammerIds	= 0
			$counterClassnames	= 0
			$counterUnknown		= 0
			$counterAll			= 0
			foreach ($lmpSection in $Lmp["data"].Keys) {
				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
					$counterHammerIds++
				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
					$counterClassnames++
				} else {
					$counterUnknown++
					Write-Host -ForegroundColor DarkYellow "This is an error"
					Write-Host $lmpSection
				}
				$counterAll++
			}

			# 3. Merge the two hashtables
			# TODO: Fix this weird shit
			$counter = 0
			$hammeridMatched = 0
			$classnameMatched = 0
			# $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"]
:lmpLoop	foreach ($lmpSection in $Lmp["data"].Keys) {
				if ($lmpSection.SubString(0,$lmpHammerIdOffset) -eq "hammerid-") {
					$hammerid = $Lmp["data"][$lmpSection]["hammerid"][0]
:vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfListLoopH			foreach ($classEntry in $Vmf["classes"][$vmfClass]) {
							if ($hammerid -eq $classEntry["properties"]["id"][0]) {
								$hammeridMatched++
								$classEntry["properties"] = $Lmp["data"][$lmpSection]
								# $vmfMerged["classes"][$vmfClass][$classEntry]["properties"] = $Lmp["data"][$lmpSection]
								break vmfHashLoopH
							}
						}
					}
					
				} elseif ($lmpSection.SubString(0,$lmpClassnameOffset) -eq "classname-") {
					$classname = $Lmp["data"][$lmpSection]["classname"][0]
:vmfHashLoopC		foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfListLoopC			foreach ($classEntry in $Vmf["classes"][$vmfClass]) {
							if ($classname -eq $classEntry["properties"]["classname"][0]) {
								$classnameMatched++
								$classEntry["properties"] = $Lmp["data"][$lmpSection]
								# $vmfMerged["classes"][$vmfClass][$classEntry]["properties"] = $Lmp["data"][$lmpSection]
								break vmfHashLoopC
							}
						}
					}

				} else {
					
					Write-Host -ForegroundColor DarkYellow "This is an error"
					Write-Host $lmpSection
				}
				$counter++
			}
			
			# $vmfMerged = [ordered]@{ }
			# foreach ($vmfSection in $Vmf.Keys) {
			# 	$vmfMerged[$vmfSection] = $Vmf[$vmfSection]
			# }

		} catch {
			# Pay attention to errors
		} finally {
			$sw.Stop()

			if (-not $Silent.IsPresent) {
				# $linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog 								-Value "`nParsing: Complete"								-Path $LogFile -OneLine
				OutLog -Property "Input hammerids"		-Value $("{0} / {1}" -f $counterHammerIds, $counterAll)	-Path $LogFile
				OutLog -Property "Input classnames"		-Value $("{0} / {1}" -f $counterClassnames, $counterAll)	-Path $LogFile
				if ($counterUnknown -gt 0) {
					OutLog -Property "Unknown sections"	-Value $("{0} / {1}" -f $counterUnknown, $counterAll)	-Path $LogFile
				}
				OutLog -Property "Merge hammerids"		-Value $("{0} / {1}" -f $hammeridMatched, $counterAll)	-Path $LogFile
				OutLog -Property "Merge classnames"		-Value $("{0} / {1}" -f $classnameMatched, $counterAll)	-Path $LogFile
				OutLog -Property "Elapsed time"		-Value $timeFormatted										-Path $LogFile
				# OutLog -Property "Speed"			-Value $("{0:n0} lines per second" -f $linesPerSecond)		-Path $LogFile
			}
			# Some harmless stats
		}

		# OutLog -Property "VMF merged type" -Value $vmfMerged.GetType().FullName -Path $LogFile

		return $Vmf
	}

	END { }
}