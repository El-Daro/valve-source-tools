
function New-VmfVisgroupsContainer {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[System.Collections.IDictionary]$Visgroup
	)
	
	PROCESS {

		$success = $false
		try {
			$Vmf["classes"]["visgroups"] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
			$Vmf["classes"]["visgroups"].Add([ordered]@{
				properties	= [ordered]@{ }
				classes		= [ordered]@{ }
			})
			$Vmf["classes"]["visgroups"][0]["classes"]["visgroup"] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
			if ($PSBoundParameters.ContainsKey('Visgroup')) {
				$Vmf["classes"]["visgroups"][0]["classes"]["visgroup"].Add($Visgroup)
			}
			$success = $true
		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to create visgroups. Continuing as is"
		}

		return $success
	}

	END { }
}