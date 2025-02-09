# delete: Deletes any properties matching both the key name and the value string
#		  The value string may have regular expressions (//)

using namespace System.Diagnostics

function ProcessStripperModDelete {
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

		foreach ($stripperProp in $Modify["modes"]["delete"][0]["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$stripperValues = $Modify["modes"]["delete"][0]["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				# The new code for the matches
				if ($vmfClassEntry["properties"].Contains($key) -and
					$vmfClassEntry["properties"][$key].Contains($value)) {
					$vmfClassEntry["properties"].Remove($key)
					$MergesCount["modifyDeleted"]++
					$MergesCount["propsDeleted"]++
				}
			}
		}

	}

	END { }
}