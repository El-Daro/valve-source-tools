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
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $false)]
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

		if ($Modify["modes"]["match"][0].Count -eq 0) {
			$MergesCount["modifySkipped"]++
			return $False
		}

:mainL	foreach ($vmfClass in $Vmf["classes"].Keys) {
			$vmfClassCount		= $Vmf["classes"][$vmfClass].get_Count()
			$progressStep		= [math]::Ceiling($vmfClassCount / 5)
			$vmfCounter			= 0
			$progressCounter	= 0
:vmfClassL	foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {
				$matchCounter = 0
				#region 1. MATCH
				$params = @{
					VmfClassEntry	= $vmfClassEntry
					Modify			= $Modify
				}
				$matchCounter = ProcessStripperModMatch @params
				#endregion
				# If all the props in the 'match' section have matched
				if ($matchCounter -eq $Modify["modes"]["match"][0]["properties"].Count) {
					#region 2. REPLACE
					if ($Modify["modes"]["replace"].get_Count() -gt 0) {
						$params = @{
							VmfClassEntry	= $vmfClassEntry
							Modify			= $Modify
							MergesCount		= $MergesCount
						}
						ProcessStripperModReplace @params
					}
					#endregion

					#region 3. DELETE
					if ($Modify["modes"]["delete"].get_Count() -gt 0) {
						$params = @{
							VmfClassEntry	= $vmfClassEntry
							Modify			= $Modify
							MergesCount		= $MergesCount
						}
						ProcessStripperModDelete @params
					}
					#endregion

					#region 4. INSERT
					if ($Modify["modes"]["insert"].get_Count() -gt 0) {
						$params = @{
							VmfClassEntry	= $vmfClassEntry
							Modify			= $Modify
							MergesCount		= $MergesCount
						}
						ProcessStripperModInsert @params
					}
					#endregion

					$MergesCount["modify"]++
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
						Activity				= $("Stripper: Merging modify {0} / {1} ..." -f
														$ProcessCounter["counter"], $ProcessCounter["total"])
					}
					ReportProgress @params
				}
				#endregion
				$vmfCounter++
			}
		}

		return $true

	}

	END { }
}