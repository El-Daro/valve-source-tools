using namespace System.Diagnostics

function ProcessStripperAdd {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Add,

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

		$class				= "entity"
		$vgnStripperAdded	= "Stripper - Added"
		$newBlock = [ordered]@{
			properties	= [ordered]@{}
			classes		= [ordered]@{}
		}
		#region hammerid
		if ($Add["properties"].Contains("hammerid")) {
			#region with HammerID
			$idKey = "id"
			$idValue = $add["properties"]["hammerid"][0]
			if ($Vmf["classes"].Contains($class)) {
				foreach ($vmfClassEntry in $Vmf["classes"][$class]) {
					if ($vmfClassEntry["properties"].Contains($idKey) -and
						$vmfClassEntry["properties"][$idKey].Contains($idValue)) {
							# Might be worth updating id instead of skipping
							# But the 'add' instruction clearly says add, not update
							$MergesCount["addSkipped"]++
							return $false
						}
				}
			}
			# We need to swap 'hammerid' with 'id' for VMF structure
			$newBlock["properties"].Add($idKey, [Collections.Generic.List[string]]::new())
			$newBlock["properties"][$idKey].Add($idValue)
		}
		#endregion
		foreach ($stripperProp in $Add["properties"].Keys) {
			if ($stripperProp.Length -gt 3 -and ($stripperProp.SubString(0,2) -eq "On") -or
												($stripperProp.SubString(0,3) -eq "Out")) {	
				try {					# See if property name starts with "On" or "Out"
					$newBlock["classes"]["connections"] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
					$newBlock["classes"]["connections"].Add([ordered]@{
						properties	= [ordered]@{ }
						classes		= [ordered]@{ }
					})
					$newBlock["classes"]["connections"][0]["properties"].Add($stripperProp, $Add["properties"][$stripperProp])
				} catch {
					# Do nothing
					Write-Host -ForegroundColor DarkYellow "Failed to copy connections: `"$stripperProp`" `"$($Add["properties"][$stripperProp])`""
				}
			} else {
				$newBlock["properties"].Add($stripperProp, $Add["properties"][$stripperProp])
			}
		}

		#region Visgroup: Stripper - Added
		if ($PSBoundParameters.ContainsKey('VisgroupidTable') -and
			$PSBoundParameters.ContainsKey('CurrentVisgroup') -and
			$false -ne $CurrentVisgroup) {
			# Create a new "Stripper - Added" visgroup if it doesn't already exist
			if (-not $visgroupidTable.Contains($vgnStripperAdded)) {
				$params = @{
					VmfSection		= $CurrentVisgroup
					Name			= $vgnStripperAdded
					Color			= $colorsTable["MediumPurple"]
					VisgroupidTable	= $visgroupidTable
				}
				$visgroupStripperAdded	= New-VmfVisgroupWrapper @params
			}

			$params = @{
				VmfSection	= $newBlock
				Color		= $colorsTable["MediumPurple"]
				VisgroupID	= $visgroupidTable[$vgnStripperAdded]
			}
			$success = Add-VmfEditor @params
		}
		#endregion

		if (-not $Vmf["classes"].Contains($class)) {
			$Vmf["classes"][$class] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
		}
		$Vmf["classes"][$class].Add($newBlock)
		$MergesCount["add"]++
		$MergesCount["propsNew"] += $Add["properties"].get_Count()
		return $true

	}

	END { }
}