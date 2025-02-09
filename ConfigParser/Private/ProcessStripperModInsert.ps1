# insert: Specifies any additional key value pairs to insert

using namespace System.Diagnostics

function ProcessStripperModInsert {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfClassEntry,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Modify,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount
	)
	
	PROCESS {

		foreach ($stripperProp in $Modify["modes"]["insert"][0]["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$stripperValues = $Modify["modes"]["insert"][0]["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				# The new code for the matches
				if ($vmfClassEntry["properties"].Contains($key) -and
					$vmfClassEntry["properties"][$key].Contains($value)) {
					break
				} else {
					$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
					$vmfClassEntry["properties"][$key].Add($value)
					$MergesCount["modifyInserted"]++
					$MergesCount["propsNew"]++
				}
			}
		}

	}

	END { }
}