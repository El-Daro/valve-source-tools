using namespace System.Diagnostics

function Merge-VmfStripper {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Stripper,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {
		
		try {

			$sw = [Stopwatch]::StartNew()

			# For LMP it counted the number of expected 'hammerid' and 'classname' merges
			$counterStripper	= EstimateOutputStripper -Stripper $Stripper -LogFile $LogFile -Silent:$Silent.IsPresent

			#region Merging Stripper into VMF
			$mergesCount		= @{
				filter			= 0
				add				= 0
				modify			= 0
				modifyReplaced	= 0
				modifyDeleted	= 0
				modifyInserted	= 0
				filterSkipped	= 0
				addSkipped		= 0
				modifySkipped	= 0
				new				= 0
				addFailed		= 0
				modifyFailed	= 0
				failed			= 0
				section			= 0
				propsEdited		= 0
				propsSkipped	= 0
				propsDeleted	= 0
				propsNew		= 0
				propsTotal		= 0
			}
			$params	= @{
				Vmf				= $Vmf
				Stripper		= $Stripper
				MergesCount		= $mergesCount
				CounterStripper	= $counterStripper
			}
			$copied = Copy-StripperIntoVmf @params

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
				# $sectionsPerSecond = ($mergesCount["section"] / $sw.ElapsedMilliseconds) * 1000
				# $propsPerSecond = ($mergesCount["propsTotal"] / $sw.ElapsedMilliseconds) * 1000
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog 							-Value "`nVMF-Stripper | Merging: Complete"													-Path $LogFile -OneLine
				OutLog -Property "Input: filters / modes"	-Value $("{0} / {1}" -f $counterStripper["filter"], $counterStripper["modes"])	-Path $LogFile
				OutLog -Property "Input: adds / modes"		-Value $("{0} / {1}" -f $counterStripper["add"], $counterStripper["modes"])		-Path $LogFile
				OutLog -Property "Input: modify / modes"	-Value $("{0} / {1}" -f $counterStripper["modify"], $counterStripper["modes"])	-Path $LogFile
				OutLog -Property "Merge: filters processed"	-Value $("{0}" -f $mergesCount["filter"])										-Path $LogFile
				OutLog -Property "Merge: add processed"		-Value $("{0} / {1}" -f $mergesCount["add"], $counterStripper["add"])											-Path $LogFile
				OutLog -Property "Merge: modify processed"	-Value $("{0}" -f $mergesCount["modify"])										-Path $LogFile
				OutLog -Property "Merged modify: replace"	-Value $("{0}" -f $mergesCount["modifyReplaced"])								-Path $LogFile
				OutLog -Property "Merged modify: delete"	-Value $("{0}" -f $mergesCount["modifyDeleted"])								-Path $LogFile
				OutLog -Property "Merged modify: insert"	-Value $("{0}" -f $mergesCount["modifyInserted"])								-Path $LogFile
				OutLog -Property "Skipped filter"			-Value $("{0}" -f $mergesCount["filterSkipped"])								-Path $LogFile
				OutLog -Property "Skipped add"				-Value $("{0}" -f $mergesCount["addSkipped"])									-Path $LogFile
				OutLog -Property "Skipped modify"			-Value $("{0}" -f $mergesCount["modifySkipped"])								-Path $LogFile
				if ($mergesCount["new"] -gt 0) {
					OutLog -Property "Merges new"			-Value $("{0} / {1}" -f $mergesCount["new"], $counterStripper["modes"])			-Path $LogFile
				}
				if ($mergesCount["failed"] -gt 0) {
					OutLog -Property "Merges failed (add)"	-Value $("{0} / {1}" -f $mergesCount["addFailed"], $mergesCount["failed"])		-Path $LogFile
					OutLog -Property "Merges failed (modify)"	-Value $("{0} / {1}" -f $mergesCount["modifyFailed"], $mergesCount["failed"])	-Path $LogFile
					OutLog -Property "Merges failed (total)"	-Value $("{0}" -f $mergesCount["failed"])									-Path $LogFile
				}
				# OutLog -Property "Properties edited"		-Value $("{0} / {1}" -f $mergesCount["propsEdited"], $mergesCount["propsTotal"])	-Path $LogFile
				# OutLog -Property "Properties skipped"		-Value $("{0} / {1}" -f $mergesCount["propsSkipped"], $mergesCount["propsTotal"])	-Path $LogFile
				# OutLog -Property "Properties new"			-Value $("{0} / {1}" -f $mergesCount["propsNew"], $mergesCount["propsTotal"])		-Path $LogFile
				OutLog -Property "Elapsed time"				-Value $timeFormatted								-Path $LogFile
				# OutLog -Property "Speed"		-Value $("{0:n0} sections per second" -f $sectionsPerSecond)	-Path $LogFile
				# OutLog -Property "Speed"		-Value $("{0:n0} properties per second" -f $propsPerSecond)		-Path $LogFile
			}
			#endregion
		}

		return $Vmf
	}

	END { }
}