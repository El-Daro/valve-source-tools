# delete: Deletes any properties matching both the key name and the value string
#		  The value string may have regular expressions (//)
# NOTE: Temporarily swapped regex check with wildcard check
# NOTE: This is a pretty fucked up function, so here's a rundown:
#		1. Determine whether or not Stripper's prop is a 'connection'
#		2. Determine whether or not both key and value are present. Do wildcard match if needed
#			- If not, skip
#			- If yes, remove

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

		foreach ($stripperProp in $Modify["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			if (($key.Length -gt 3 -and ($key.SubString(0,2) -eq "On") -or
										($key.SubString(0,3) -eq "Out")) -and
										 $vmfClassEntry["classes"].Contains("connections")) {
				$vmfBlock = $vmfClassEntry["classes"]["connections"][0]
			} else {
				$vmfBlock = $vmfClassEntry
			}
			$stripperValues = $Modify["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				#region RegEx
				if ($value.Length -gt 2 -and $value[0] -eq "/" -and $value[$value.Length - 1] -eq "/") {
					$stripperValueRegex = $value.SubString(1, $value.Length - 2) 
					if ($vmfBlock["properties"].Contains($key)) {
						try {
							foreach ($vmfPropValue in $vmfBlock["properties"][$key]) {
								if ($vmfPropValue -like $stripperValueRegex) {
									$vmfBlock["properties"].Remove($key)
									$MergesCount["modifyDeleted"]++
									$MergesCount["propsDeleted"]++
									break
								}
							}
						} catch {
							Write-Debug "$($MyInvocation.MyCommand):  Failed to do a regex check"
						}
					} else {
						break
					}
				#endregion
				} elseif ($vmfBlock["properties"].Contains($key) -and
						  $vmfBlock["properties"][$key].Contains($value)) {
					$vmfBlock["properties"].Remove($key)
					$MergesCount["modifyDeleted"]++
					$MergesCount["propsDeleted"]++
				}
			}
		}

	}

	END { }
}