# replace: Replaces the values of any properties that have the same key name
# NOTE: This is a pretty fucked up function, so here's a rundown:
#		1. Determine whether or not Stripper's prop is a 'connection'
#			- If no, go to 4
#		2. Determine whether or not VMF block already has 'connections' class
#			- If yes, go to 4
#		3. Create connections class and add the key-value pair(s)
#		4. Determine whether or not the key is present
#			- If not, skip
#			- If yes, replace value with Stripper's value

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

		foreach ($stripperProp in $Modify["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$IsConnections = $false
			if ($key.Length -gt 3 -and ($key.SubString(0,2) -eq "On") -or
									   ($key.SubString(0,3) -eq "Out")) {
				$IsConnections = $true
			}
			$stripperValues = $Modify["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				#region Shitcode
				if ($IsConnections) {			# If the property being inserted is a connection
					if ($vmfClassEntry["classes"].Contains("connections")) {
						if (-not $vmfClassEntry["classes"]["connections"][0]["properties"].Contains($key)) {
							break
						}
						$vmfClassEntry["classes"]["connections"][0]["properties"][$key] = [Collections.Generic.List[string]]::new()
						$vmfClassEntry["classes"]["connections"][0]["properties"][$key].Add($value)
					}
				} else {
					if (-not $vmfClassEntry["properties"].Contains($key)) {
						break
					}
					$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
					$vmfClassEntry["properties"][$key].Add($value)
				}
				$MergesCount["modifyReplaced"]++
				$MergesCount["propsEdited"]++
				#endregion
			}
		}

	}

	END { }
}