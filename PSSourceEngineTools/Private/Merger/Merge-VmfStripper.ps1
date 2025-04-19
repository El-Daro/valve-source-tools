# TODO: Implement visgroups generation

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
		$VisgroupidTable,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$Visgroups,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Demo
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
				VisgroupidTable	= $visgroupidTable
				Visgroups		= $visgroups
				MergesCount		= $mergesCount
				CounterStripper	= $counterStripper
				StopWatch		= [ref]$sw
				Demo			= $Demo.IsPresent
			}
			$copied = Copy-StripperIntoVmf @params

			if (-not $copied) {
				Throw "$($MyInvocation.MyCommand):  Failed to copy Stripper into VMF"
			}
			#endregion
		} catch {
			# Pay attention to errors
		} finally {
			$sw.Stop()

			#region Logging
			if (-not $Silent.IsPresent) {
				# if ($sw.ElapsedMilliseconds -gt 0) {
				# 	$sectionsPerSecond	= ($mergesCount["section"] / $sw.ElapsedMilliseconds) * 1000
				# 	$propsPerSecond		= ($mergesCount["propsTotal"] / $sw.ElapsedMilliseconds) * 1000
				# } else {
				# 	$sectionsPerSecond	= $mergesCount["section"] * 1000
				# 	$propsPerSecond		= $mergesCount["propsTotal"] * 1000
				# }
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				Out-Log 							-Value "`nVMF-Stripper | Merging: Complete"													-Path $LogFile -OneLine
				Out-Log -Property "Input: filters / modes"	-Value $("{0} / {1}" -f $counterStripper["filter"], $counterStripper["modes"])	-Path $LogFile
				Out-Log -Property "Input: adds / modes"		-Value $("{0} / {1}" -f $counterStripper["add"], $counterStripper["modes"])		-Path $LogFile
				Out-Log -Property "Input: modify / modes"	-Value $("{0} / {1}" -f $counterStripper["modify"], $counterStripper["modes"])	-Path $LogFile
				Out-Log -Property "Merge: filters processed"	-Value $("{0}" -f $mergesCount["filter"])										-Path $LogFile
				Out-Log -Property "Merge: add processed"		-Value $("{0} / {1}" -f $mergesCount["add"], $counterStripper["add"])			-Path $LogFile
				Out-Log -Property "Merge: modify processed"	-Value $("{0}" -f $mergesCount["modify"])										-Path $LogFile
				Out-Log -Property "Merged modify - replace"	-Value $("{0}" -f $mergesCount["modifyReplaced"])								-Path $LogFile
				Out-Log -Property "Merged modify - delete"	-Value $("{0}" -f $mergesCount["modifyDeleted"])								-Path $LogFile
				Out-Log -Property "Merged modify - insert"	-Value $("{0}" -f $mergesCount["modifyInserted"])								-Path $LogFile
				Out-Log -Property "Skipped filter"			-Value $("{0}" -f $mergesCount["filterSkipped"])								-Path $LogFile
				Out-Log -Property "Skipped add"				-Value $("{0}" -f $mergesCount["addSkipped"])									-Path $LogFile
				Out-Log -Property "Skipped modify"			-Value $("{0}" -f $mergesCount["modifySkipped"])								-Path $LogFile
				if ($mergesCount["new"] -gt 0) {
					Out-Log -Property "Merges new"			-Value $("{0} / {1}" -f $mergesCount["new"], $counterStripper["modes"])			-Path $LogFile
				}
				if ($mergesCount["failed"] -gt 0) {
					Out-Log -Property "Merges failed (add)"	-Value $("{0} / {1}" -f $mergesCount["addFailed"], $mergesCount["failed"])		-Path $LogFile
					Out-Log -Property "Merges failed (modify)"	-Value $("{0} / {1}" -f $mergesCount["modifyFailed"], $mergesCount["failed"])	-Path $LogFile
					Out-Log -Property "Merges failed (total)"	-Value $("{0}" -f $mergesCount["failed"])									-Path $LogFile
				}
				# Out-Log -Property "Properties edited"		-Value $("{0} / {1}" -f $mergesCount["propsEdited"], $mergesCount["propsTotal"])	-Path $LogFile
				# Out-Log -Property "Properties skipped"		-Value $("{0} / {1}" -f $mergesCount["propsSkipped"], $mergesCount["propsTotal"])	-Path $LogFile
				# Out-Log -Property "Properties new"			-Value $("{0} / {1}" -f $mergesCount["propsNew"], $mergesCount["propsTotal"])		-Path $LogFile
				Out-Log -Property "Elapsed time"				-Value $timeFormatted								-Path $LogFile
				# Out-Log -Property "Speed"		-Value $("{0:n0} sections per second" -f $sectionsPerSecond)	-Path $LogFile
				# Out-Log -Property "Speed"		-Value $("{0:n0} properties per second" -f $propsPerSecond)		-Path $LogFile
			}
			#endregion
		}

		return $Vmf
	}

	END { }
}