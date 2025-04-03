using namespace System.Diagnostics

function Get-MaxVisgroupidRecursive {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 2,
		Mandatory = $false)]
		$VisgroupidMax = 0
	)
	
	PROCESS {
		
		try {

			$property	= "visgroupid"
			if ($Vmf["properties"].Contains($property) -and $Vmf["properties"][$property].get_Count() -gt 0) {
				foreach ($propertyEntry in $Vmf["properties"][$property]) {
					try {
						if ([int]$propertyEntry -gt [int]$visgroupidMax) {
							$visgroupidMax = $propertyEntry
						}
					} catch {
						# None
					}
				}
			}

			$class = "visgroup"
			if ($Vmf["classes"].Contains($class) -and $Vmf["classes"][$class].get_Count() -gt 0) {
				foreach ($classEntry in $Vmf["classes"][$class]) {
					$params = @{
						Vmf				= $classEntry
						VisgroupidMax	= $VisgroupidMax
					}
					$VisgroupidMax = Get-MaxVisgroupidRecursive @params
				}
			}

		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to get max visgroupid. Continuing as is"
			Write-Debug "$($MyInvocation.MyCommand):  Current VisgroupidMax: $VisgroupidMax"
		}

		return $VisgroupidMax
	}

	END { }
}