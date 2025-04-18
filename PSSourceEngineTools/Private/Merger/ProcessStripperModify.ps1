# match: Matches all entities that have the listed model and classname
#		 You can use regular expressions (//) for any key values here.
# replace: Replaces the values of any properties that have the same key name
# delete: Deletes any properties matching both the key name and the value string
#		  The value string may have regular expressions (//)
# insert: Specifies any additional key value pairs to insert

using namespace System.Diagnostics

function ProcessStripperModify {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Modify,

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
		Mandatory = $false)]
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

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		if ($Modify["modes"]["match"][0].get_Count() -eq 0) {
			$MergesCount["modifySkipped"]++
			return $False
		}

# :mainL	foreach ($vmfClass in $Vmf["classes"].Keys) {
		$class					= "entity"
		$vgnStripperModified	= "Stripper - Modified"
		if (-not $Vmf["classes"].Contains($class) -or $Vmf["classes"][$class].get_Count() -eq 0) {
			return $false
		}
		$vmfClassCount		= $Vmf["classes"][$class].get_Count()
		$progressStep		= [math]::Ceiling($vmfClassCount / 3)
		$vmfCounter			= 0
		$progressCounter	= 0
		foreach ($vmfClassEntry in $Vmf["classes"][$class]) {
			$matchCounter	= 0
			#region 1. MATCH
			$params = @{
				VmfClassEntry	= $vmfClassEntry
				StripperBlock	= $Modify["modes"]["match"][0]
			}
			$matchCounter	= ProcessStripperModMatch @params
			#endregion
			# If all the props in the 'match' section have matched
			if ($matchCounter -eq $Modify["modes"]["match"][0]["properties"].get_Count()) {
				$modified = $false
				#region 2. REPLACE
				if ($Modify["modes"]["replace"].get_Count() -gt 0) {
					$params = @{
						VmfClassEntry	= $vmfClassEntry
						Modify			= $Modify["modes"]["replace"][0]
						MergesCount		= $MergesCount
					}
					ProcessStripperModReplace @params
					$modified = $true
				}
				#endregion

				#region 3. DELETE
				if ($Modify["modes"]["delete"].get_Count() -gt 0) {
					$modifyDeletedPrev = $MergesCount["modifyDeleted"]
					$params = @{
						VmfClassEntry	= $vmfClassEntry
						Modify			= $Modify["modes"]["delete"][0]
						MergesCount		= $MergesCount
					}
					ProcessStripperModDelete @params
					if ($MergesCount["modifyDeleted"] -gt $modifyDeletedPrev) {
						$modified = $true
					}
				}
				#endregion

				#region 4. INSERT
				if ($Modify["modes"]["insert"].get_Count() -gt 0) {
					$params = @{
						VmfClassEntry	= $vmfClassEntry
						Modify			= $Modify["modes"]["insert"][0]
						MergesCount		= $MergesCount
					}
					ProcessStripperModInsert @params
					$modified = $true
				}
				#endregion

				#region Visgroup: Stripper - Modified
				if ($PSBoundParameters.ContainsKey('VisgroupidTable') -and
					$PSBoundParameters.ContainsKey('CurrentVisgroup') -and
					$false -ne $CurrentVisgroup -and $modified) {
					# Create a new "Stripper - Modified" visgroup if it doesn't already exist
					if (-not $visgroupidTable.Contains($vgnStripperModified)) {
						$params = @{
							VmfSection		= $CurrentVisgroup
							Name			= $vgnStripperModified
							Color			= $colorsTable["UltraViolet"]
							VisgroupidTable	= $visgroupidTable
						}
						$visgroupStripperMod	= New-VmfVisgroupWrapper @params
					}

					$params = @{
						VmfSection	= $vmfClassEntry
						Color		= $colorsTable["UltraViolet"]
						VisgroupID	= $visgroupidTable[$vgnStripperModified]
					}
					$success = Add-VmfEditor @params
				}
				#endregion

				$MergesCount["modify"]++
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
					Activity				= $("Stripper: Merging modify {0} / {1} ..." -f
													$ProcessCounter["counter"], $ProcessCounter["total"])
				}
				ReportProgress @params
			}
			#endregion
			$vmfCounter++
		}

		return $true

	}

	END { }
}