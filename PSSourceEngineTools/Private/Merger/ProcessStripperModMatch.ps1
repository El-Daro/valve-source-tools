# match: Matches all entities that have the listed model and classname
#		 You can use regular expressions (//) for any key values here.
# NOTE: Temporarily swapped regex check with wildcard check

using namespace System.Diagnostics

function ProcessStripperModMatch {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfClassEntry,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$StripperBlock
	)
	
	PROCESS {

		$matchCounter = 0
:main	foreach ($stripperProp in $StripperBlock["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$stripperValues = $StripperBlock["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				# The new code for the matches
				if ($value.Length -gt 2 -and $value[0] -eq "/" -and $value[$value.Length - 1] -eq "/") {
					$stripperValueRegex = $value.SubString(1, $value.Length - 2) 
					if ($vmfClassEntry["properties"].Contains($key)) {
						try {
							foreach ($vmfPropValue in $vmfClassEntry["properties"][$key]) {
								if ($vmfPropValue -like $stripperValueRegex) {
									$matchCounter++
									break
								}
							}
						} catch {
							Write-Debug "$($MyInvocation.MyCommand):  Failed to do a regex check"
						}
					} else {
						break main
					}
				} else {
					if ($vmfClassEntry["properties"].Contains($key) -and
						$vmfClassEntry["properties"][$key].Contains($value)) {
						$matchCounter++
					} else {
						break main
					}
				}
			}
		}

		return $matchCounter

	}

	END { }
}