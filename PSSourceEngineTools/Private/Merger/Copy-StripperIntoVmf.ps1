using namespace System.Diagnostics

function Copy-StripperIntoVmf {
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
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 5,
		Mandatory = $true)]
		$CounterStripper,

		[Parameter(Position = 6,
		Mandatory = $true)]
		[ref]$StopWatch,

		[Parameter(Position = 7,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Demo
	)
	
	PROCESS {
		
		try {

			#region VARIABLES
			$MergesCount["filter"]			= 0			# +
			$MergesCount["add"]				= 0			# +
			$MergesCount["modify"]			= 0			# +
			$MergesCount["modifyReplaced"]	= 0			# +
			$MergesCount["modifyDeleted"]	= 0			# +
			$MergesCount["modifyInserted"]	= 0			# +

			$MergesCount["filterSkipped"]	= 0			# +
			$MergesCount["addSkipped"]		= 0			# +
			$MergesCount["modifySkipped"]	= 0			# +

			$MergesCount["new"]				= 0			# -
			$MergesCount["addFailed"]		= 0			# +
			$MergesCount["modifyFailed"]	= 0			# +
			$MergesCount["failed"]			= 0			# +
			$MergesCount["section"]			= 0			# - (*)

			$MergesCount["propsNew"]		= 0			# + (?)
			$MergesCount["propsEdited"]		= 0			# +
			$MergesCount["propsDeleted"]	= 0			# + (?)
			$MergesCount["propsSkipped"]	= 0			# -
			$MergesCount["propsTotal"]		= 0
			# $progressCounter				= 0
			# $progressStep					= $CounterStripper["total"] / 10
			$colorsTable					= Get-ColorsTable
			$vgnStripper					= "Stripper"				# vgn = visgroupName
			$vgnStripperFiltered			= "Stripper - Filtered"
			$vgnStripperAdded				= "Stripper - Added"
			$vgnStripperModified			= "Stripper - Modified"
			if ($PSBoundParameters.ContainsKey('Visgroups')) {
				$currentVisgroup			= $Visgroups
			} else {
				$currentVisgroup			= $false
			}
			#endregion

			#region Visgroups
			# Create a new "Stripper" visgroup if it doesn't already exist
			# NOTE: This visgroup is initially created with a marker (additional parameter)
			#		It gets either deleted or cleaned out in the end,
			#		depending on whether any rules were actually applied
			if ($PSBoundParameters.ContainsKey('VisgroupidTable') -and
				$PSBoundParameters.ContainsKey('Visgroups')) {
				if (-not $visgroupidTable.Contains($vgnStripper)) {
					$params = @{
						VmfSection		= $currentVisgroup
						Name			= $vgnStripper
						Color			= $colorsTable["Magenta"]
						VisgroupidTable	= $visgroupidTable
						MarkTemporary	= $true
					}
					$currentVisgroup	= New-VmfVisgroupWrapper @params
				}
			}
			#endregion

			if ($Stripper["modes"]["filter"].get_Count() -gt 0) {
				$filterCounter	= @{
					total		= $Stripper["modes"]["filter"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:filterLoop		foreach ($filter in $Stripper["modes"]["filter"]) {
					$filterProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Filter			= $filter
						VisgroupidTable	= $visgroupidTable
						CurrentVisgroup	= $currentVisgroup
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $filterCounter
						Demo			= $Demo.IsPresent
					}
					$filterProcessed = ProcessStripperFilter @params
					$filterCounter["counter"]++
					if (-not $filterProcessed) {
						$MergesCount["failed"]++
					}
				}
				$sw.Stop()
			}

			if ($Stripper["modes"]["add"].get_Count() -gt 0) {
				$addCounter	= @{
					total		= $Stripper["modes"]["add"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:addLoop		foreach ($add in $Stripper["modes"]["add"]) {
					$addProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Add				= $add
						VisgroupidTable	= $visgroupidTable
						CurrentVisgroup	= $currentVisgroup
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $addCounter
					}
					# Adding is O(1), so we don't need to create progress bar. Params passed for future use
					$addProcessed = ProcessStripperAdd @params
					$addCounter["counter"]++
					if (-not $addProcessed) {
						$MergesCount["addFailed"]++
					}
				}
				$sw.Stop()
			}

			# Different approach to modifies
			if ($Stripper["modes"]["modify"].get_Count() -gt 0) {
				$modifyCounter	= @{
					total		= $Stripper["modes"]["modify"].get_Count()
					counter		= 0
				}
				$sw = [Stopwatch]::StartNew()
:modLoop		foreach ($modify in $Stripper["modes"]["modify"]) {
					$modifyProcessed = $false
					$params	= @{
						Vmf				= $Vmf
						Modify			= $modify
						VisgroupidTable	= $visgroupidTable
						CurrentVisgroup	= $currentVisgroup
						MergesCount		= $MergesCount
						CounterStripper	= $CounterStripper
						StopWatch		= [ref]$sw
						ProcessCounter	= $modifyCounter
					}
					$modifyProcessed = ProcessStripperModify @params
					$modifyCounter["counter"]++
					if (-not $modifyProcessed) {
						$MergesCount["modifyFailed"]++
					}
				}
				$sw.Stop()
			}

			# The container visgroup - Stripper - is created prior to processing all the rules
			# Here it gets either deleted or cleaned, depending on whether any rules were actually applied
			if ($currentVisgroup["properties"].Contains("temporary")) {
				if (-not $visgroupidTable.Contains($vgnStripperFiltered) -and
					-not $visgroupidTable.Contains($vgnStripperAdded) -and
					-not $visgroupidTable.Contains($vgnStripperModified)) {
					$params = @{
						Vmf			= $Visgroups
						MatchSet	= @{ name = $vgnStripper }
					}
					$success = Remove-VmfSection @params
				} else {
					$currentVisgroup["properties"].Remove("temporary")
				}
			}

			$MergesCount["failed"]		= $MergesCount["addFailed"] + $MergesCount["modifyFailed"]
			$MergesCount["propsTotal"]	= $MergesCount["propsEdited"] + $MergesCount["propsSkipped"] + $MergesCount["propsNew"] + $MergesCount["propsDeleted"]
			return $true

		} catch {
			# Pay attention to errors
			return $false
		}
	}

	END { }
}