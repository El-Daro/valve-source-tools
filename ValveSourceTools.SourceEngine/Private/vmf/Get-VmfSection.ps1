# TODO: Rewrite the loop and loop breaker

using namespace System.Diagnostics

function Get-VmfSection {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfSection,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$MatchSet,		# Example: @{ name = "lmp" }

		[Parameter(Position = 2,
		Mandatory = $false)]
		$ClassName = "visgroup"
	)
	
	PROCESS {
		
		$returnSection	= $false

		try {

			$matchCounter	= 0
			# $property		= "visgroupid"
:main		foreach ($matchKey in $MatchSet.Keys) {
				$matchValue	= $MatchSet[$matchKey]
				if ($VmfSection["properties"].Contains($matchKey) -and
					$VmfSection["properties"][$matchKey].Contains($matchValue)) {
					$matchCounter++	
				} else {
					break main
				}
			}

			if ($matchCounter -eq $MatchSet.get_Count()) {
				# $returnValue = $VmfSection["properties"][$property]
				return $VmfSection
			} else {
				# $class = "visgroup"
				if ($VmfSection["classes"].Contains($ClassName) -and $VmfSection["classes"][$ClassName].get_Count() -gt 0) {
					foreach ($classEntry in $VmfSection["classes"][$ClassName]) {
						$params = @{
							VmfSection	= $classEntry
							MatchSet	= $MatchSet
							ClassName	= $ClassName
						}
						$returnSection	= Get-VmfSection @params
					}
				}
			}

		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to get VMF section. Continuing as is"
		}

		return $returnSection
	}

	END { }
}