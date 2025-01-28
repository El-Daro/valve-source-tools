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

			# 1. Analyze the lmp hashtable
			#region Analyzing LMP
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
			#endregion

			# 2. Merge the two hashtables
			# TODO: Make sure all the LMP contents get copied
			# TODO: Refactor into its own function
			$counter			= 0
			$hammeridMatched	= 0
			$classnameMatched	= 0
			$matchesFailed		= 0
			$propsEdited		= 0
			$propsSkipped		= 0
			$progressCounter	= 0
			$progressStep		= $counterAll.Count / 50
			# $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"]
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
					$matchesFailed++
					Write-Host -ForegroundColor DarkYellow "This is an error"
					Write-Host $lmpSection
				}
				if ($idToMatch) {
:vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfListLoopH			foreach ($classEntry in $Vmf["classes"][$vmfClass]) {
							if ($idToMatch -eq $classEntry["properties"][$matchBy][0]) {
								if ($matchBy -eq "id") {
									$hammeridMatched++
								} else {
									$classnameMatched++
								}
								$params = @{
									VmfSection	= $classEntry
									LmpSection	= $Lmp["data"][$lmpSection]
									PropsEdited	= [ref]$propsEdited
									PropsSkipped = [ref]$propsSkipped
									LogFile		= $LogFile
									Silent		= $Silent.IsPresent
								}
								Copy-LmpSection @params
								break vmfHashLoopH
							}
						}
					}
				}
				$counter++

				if ($counter -ge $progressStep -and [math]::Floor($counter / $progressStep) -gt $progressCounter) { 
					$progressCounter++
					$elapsedMilliseconds	= $sw.ElapsedMilliseconds
					$estimatedMilliseconds	= ($counterAll / $counter) * $elapsedMilliseconds
					$params = @{
						currentLine				= $counter
						LinesCount				= $counterAll
						EstimatedMilliseconds	= $estimatedMilliseconds
						ElapsedMilliseconds		= $sw.ElapsedMilliseconds
						Activity				= "Merging..."
					}
					ReportProgress @params
				}
			}

			$propsAll = $propsEdited + $propsSkipped
		} catch {
			# Pay attention to errors
		} finally {
			$sw.Stop()

			if (-not $Silent.IsPresent) {
				# $linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog 								-Value "`nVMF-LMP | Merging: Complete"								-Path $LogFile -OneLine
				OutLog -Property "Input hammerids"		-Value $("{0} / {1}" -f $counterHammerIds, $counterAll)	-Path $LogFile
				OutLog -Property "Input classnames"		-Value $("{0} / {1}" -f $counterClassnames, $counterAll)	-Path $LogFile
				if ($counterUnknown -gt 0) {
					OutLog -Property "Unknown sections"	-Value $("{0} / {1}" -f $counterUnknown, $counterAll)	-Path $LogFile
				}
				OutLog -Property "Merged hammerids"		-Value $("{0} / {1}" -f $hammeridMatched, $counterAll)	-Path $LogFile
				OutLog -Property "Merged classnames"	-Value $("{0} / {1}" -f $classnameMatched, $counterAll)	-Path $LogFile
				if ($matchesFailed -gt 0) {
					OutLog -Property "Matches failed"	-Value $("{0} / {1}" -f $matchesFailed, $counterAll)	-Path $LogFile
				}
				OutLog -Property "Properties edited"	-Value $("{0} / {1}" -f $propsEdited, $propsAll)		-Path $LogFile
				OutLog -Property "Properties skipped"	-Value $("{0} / {1}" -f $propsSkipped, $propsAll)		-Path $LogFile
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