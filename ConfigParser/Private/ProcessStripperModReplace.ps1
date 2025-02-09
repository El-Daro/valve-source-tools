# replace: Replaces the values of any properties that have the same key name

using namespace System.Diagnostics

function ProcessStripperModReplace {
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

		foreach ($stripperProp in $Modify["modes"]["replace"][0]["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$stripperValues = $Modify["modes"]["replace"][0]["properties" ][$stripperProp]
			foreach ($value in $stripperValues) {
				# The new code for the matches
				if ($vmfClassEntry["properties"].Contains($key)) {
					$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
					$vmfClassEntry["properties"][$key].Add($value)
					$MergesCount["modifyReplaced"]++
					$MergesCount["propsEdited"]++
				} else {
					break
				}
			}
		}

	}

	END { }
}