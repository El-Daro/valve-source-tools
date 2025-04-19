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

		$lmpHammerIdOffset	= 9
		$lmpClassnameOffset	= 10
		
		try {

			$sw = [Stopwatch]::StartNew()

			#region Analyzing LMP
			$params = @{
				Lmp					= $Lmp
				LmpHammerIdOffset	= $lmpHammerIdOffset
				LmpClassnameOffset	= $lmpClassnameOffset
			}
			$counterLmp = EstimateMergerInputLmp @params
			#endregion

			#region Merging LMP into VMF
			$mergesCount		= @{
				hammerid		= 0
				classname		= 0
				new				= 0
				failed			= 0
				section			= 0
				propsEdited		= 0
				propsSkipped	= 0
				propsNew		= 0
				propsTotal		= 0
			}
			$params	= @{
				Vmf				= $Vmf
				Lmp				= $Lmp
				MergesCount		= $mergesCount
				CounterLmp		= $counterLmp
				VisgroupidTable	= $visgroupidTable
				Visgroups		= $Visgroups
				Demo			= $Demo.IsPresent
			}
			$copied = Copy-LmpIntoVmf @params

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
				if ($sw.ElapsedMilliseconds -gt 0) {
					$sectionsPerSecond	= ($mergesCount["section"] / $sw.ElapsedMilliseconds) * 1000
					$propsPerSecond		= ($mergesCount["propsTotal"] / $sw.ElapsedMilliseconds) * 1000
				} else {
					$sectionsPerSecond	= $mergesCount["section"] * 1000
					$propsPerSecond		= $mergesCount["propsTotal"] * 1000
				}
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				Out-Log 							-Value "`nVMF-LMP | Merging: Complete"														-Path $LogFile -OneLine
				Out-Log -Property "Input hammerids"		-Value $("{0} / {1}" -f $counterLmp["hammerid"], $counterLmp["total"])				-Path $LogFile
				Out-Log -Property "Input classnames"		-Value $("{0} / {1}" -f $counterLmp["classname"], $counterLmp["total"])				-Path $LogFile
				if ($counterLmp["unknown"] -gt 0) {
					Out-Log -Property "Unknown sections"	-Value $("{0} / {1}" -f $counterLmp["unknown"], $counterLmp["total"])				-Path $LogFile
				}
				Out-Log -Property "Merged hammerids"		-Value $("{0} / {1}" -f $mergesCount["hammerid"], $counterLmp["total"])				-Path $LogFile
				Out-Log -Property "Merged classnames"	-Value $("{0} / {1}" -f $mergesCount["classname"], $counterLmp["total"])			-Path $LogFile
				if ($mergesCount["new"] -gt 0) {
					Out-Log -Property "Merges new"		-Value $("{0} / {1}" -f $mergesCount["new"], $counterLmp["total"])					-Path $LogFile
				}
				if ($mergesCount["failed"] -gt 0) {
					Out-Log -Property "Merges failed"	-Value $("{0} / {1}" -f $mergesCount["failed"], $counterLmp["total"])				-Path $LogFile
				}
				Out-Log -Property "Properties edited"	-Value $("{0} / {1}" -f $mergesCount["propsEdited"], $mergesCount["propsTotal"])	-Path $LogFile
				Out-Log -Property "Properties skipped"	-Value $("{0} / {1}" -f $mergesCount["propsSkipped"], $mergesCount["propsTotal"])	-Path $LogFile
				Out-Log -Property "Properties new"		-Value $("{0} / {1}" -f $mergesCount["propsNew"], $mergesCount["propsTotal"])		-Path $LogFile
				Out-Log -Property "Elapsed time"			-Value $timeFormatted																-Path $LogFile
				Out-Log -Property "Speed"				-Value $("{0:n0} sections per second" -f $sectionsPerSecond)						-Path $LogFile
				Out-Log -Property "Speed"				-Value $("{0:n0} properties per second" -f $propsPerSecond)							-Path $LogFile
			}
			#endregion
		}

		return $Vmf
	}

	END { }
}