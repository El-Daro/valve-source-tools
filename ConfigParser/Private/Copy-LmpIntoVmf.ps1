# TODO: Make sure all the LMP contents get copied

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
					$MergesCount["failed"]++
					Write-Host -ForegroundColor DarkYellow "This is an error"
					Write-Host $lmpSection
				}
				if ($idToMatch) {
:vmfHashLoopH		foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfListLoopH			foreach ($classEntry in $Vmf["classes"][$vmfClass]) {
							if ($idToMatch -eq $classEntry["properties"][$matchBy][0]) {
								if ($matchBy -eq "id") {
									$MergesCount["hammerid"]++
								} else {
									$MergesCount["classname"]++
								}
								$params = @{
									VmfSection	= $classEntry
									LmpSection	= $Lmp["data"][$lmpSection]
									MergesCount	= $MergesCount
									# PropsSkipped = [ref]$propsSkipped
									LogFile		= $LogFile
									Silent		= $Silent.IsPresent
								}
								Copy-LmpSection @params

								#region In-house copying function (for testing purposes)
								# foreach ($propertyName in $Lmp["data"][$lmpSection].Keys) {
								# 	if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
								# 		if ($classEntry["properties"][$propertyName] -ne $Lmp["data"][$lmpSection][$propertyName]) {
								# 			$mergesCount["propsEdited"]++
								# 			if ($propertyName.Length -gt 3 -and ($propertyName.SubString(0,2) -eq "On") -or
								# 												($propertyName.SubString(0,3) -eq "Out")) {	
								# 				try {														# See if property name starts with "On"
								# 					if ($classEntry["classes"].Contains("connections")) {	# And put it in the 'connections' class
								# 						$classEntry["classes"]["connections"][0]["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
								# 					} else {
								# 						$classEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
								# 					}
								# 				} catch {
								# 					# Do nothing
								# 					Write-Host -ForegroundColor DarkYellow "Failed to copy connections. Hammerid: $($Lmp["data"][$lmpSection]["hammerid"])"
								# 				}
								# 			} else {
								# 				$classEntry["properties"][$propertyName] = $Lmp["data"][$lmpSection][$propertyName]
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

			$MergesCount["propsTotal"] = $MergesCount["propsEdited"] + $MergesCount["propsSkipped"]
			return $true

		} catch {
			# Pay attention to errors
			return $false
		} finally {
			
		}
	}

	END { }
}