using namespace System.Diagnostics

function Remove-VmfSection {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$MatchSet,		# @{ Name = "Custom" }
		
		[Parameter(Position = 1,
		Mandatory = $false)]
		$Class = "visgroup"
	)
	
	PROCESS {

		$indexesToRemove	= @()
		$success			= $false
		try {
			if (-not $Vmf["classes"].Contains($Class) -or
				-not $Vmf["classes"][$Class].get_Count() -gt 0) {
				return $false
			}
			foreach ($VmfClassEntry in $Vmf["classes"][$class]) {
				$matchCounter	= 0
:main			foreach ($matchKey in $MatchSet.Keys) {
					$matchValue	= $MatchSet[$matchKey]
					if (	$VmfClassEntry["properties"].Contains($matchKey) -and
							$VmfClassEntry["properties"][$matchKey].Contains($matchValue)) {
						$matchCounter++	
					} else {
						break main
					}
				}
				if ($matchCounter -eq $MatchSet.get_Count()) {
					$index = $Vmf["classes"][$class].IndexOf($VmfClassEntry)
					$indexesToRemove += $index
				}
			}

			for ($i = $indexesToRemove.Count - 1; $i -ge 0; $i--) {
				Write-Debug $("Remove-VmfSection: Removing at {0} / {1}" -f
					$indexesToRemove[$i], $($Vmf["classes"][$class].get_Count()))
				$Vmf["classes"][$class].RemoveAt($indexesToRemove[$i])
			}
			$success	= $true
		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to remove '$Name' section. Continuing as is"
		}
		# Consider returning the visgroup section
		return $success
	}

	END { }
}