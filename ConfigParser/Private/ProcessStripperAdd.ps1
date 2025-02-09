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
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$CounterStripper,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		# Add a new section to VMF file
		if ($Add["properties"].Contains("hammerid")) {
			$idKey = "id"
			$idValue = $add["properties"]["hammerid"][0]
			foreach ($vmfClassEntry in $Vmf["classes"]["entity"]) {
				if ($vmfClassEntry["properties"].Contains($idKey) -and
					$vmfClassEntry["properties"][$idKey].Contains($idValue)) {
						# Might be worth updating id instead of skipping
						# But the 'add' instruction clearly says add, not update
						$MergesCount["addSkipped"]++
						return $false
					}
			}

			# We need to swap 'hammerid' with 'id' for VMF structure
			$newBlock = [ordered]@{
				properties	= [ordered]@{}
				classes		= [ordered]@{}
			}
			$newBlock["properties"].Add($idKey, [Collections.Generic.List[string]]::new())
			$newBlock["properties"][$idKey].Add($idValue)
			foreach ($propKey in $Add["properties"].Keys) {
				if ($propKey -ne "hammerid") {
					$newBlock["properties"].Add($propKey, $Add["properties"][$propKey])
				}
			}
			$Vmf["classes"]["entity"].Add($newBlock)
		} else {
			$Vmf["classes"]["entity"].Add($Add)
		}
		$MergesCount["add"]++
		$MergesCount["propsNew"] += $Add["properties"].Count
		return $true

	}

	END { }
}