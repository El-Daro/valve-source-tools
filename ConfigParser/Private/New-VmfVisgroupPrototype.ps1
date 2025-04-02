# TODO: Reconsider the purpose of the dummy variable

function New-VmfVisgroupPrototype {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		$VisgroupidTable,

		[Parameter(Position = 2,
		Mandatory = $false)]
		$Visgroups,

		[Parameter(Position = 3,
		Mandatory = $true)]
		$Name,

		[Parameter(Position = 4,
		Mandatory = $false)]
		$ParentName,

		[Parameter(Position = 5,
		Mandatory = $false)]
		$Color = "128 128 128"
	)

	PROCESS {

		# 0. Return var
		$parentVisgroup	= $false
		$targetVisgroup = $false
		$visgroupIdsHash	= @{}
		# 1. See if it already exists
		if ($Vmf["classes"].Contains("visgroups") -and $Vmf["classes"]["visgroups"].get_Count() -gt 0) {
			if ($PSBoundParameters.ContainsKey('ParentName')) {
				$params = @{
					VmfSection	= $Vmf["classes"]["visgroups"][0]
					MatchSet	= @{ name = $ParentName }
					ClassName	= "visgroup"
				}
				$parentVisgroup	= Get-VmfSection @params

				if ($parentVisgroup -and $parentVisgroup["classes"].Contains("visgroup") -and 
										 $parentVisgroup["classes"]["visgroup"].get_Count() -gt 0) {
					$params = @{
						VmfSection	= $parentVisgroup[0]
						MatchSet	= @{ name = $Name }
						ClassName	= "visgroup"
					}
					$targetVisgroup	= Get-VmfSection @params
				}
			} else {
				$params = @{
					VmfSection	= $Vmf["classes"]["visgroups"][0]
					MatchSet	= @{ name = $Name }
					ClassName	= "visgroup"
				}
				$targetVisgroup	= Get-VmfSection @params
			}
			
			if ($targetVisgroup -and $targetVisgroup["properties"].Contains("visgroupid") -and 
								 	 $targetVisgroup["properties"]["visgroupid"].get_Count() -gt 0) {
				$visgroupIdsHash[$name] = $targetVisgroup["properties"]["visgroupid"][0]	# Read existing one
			} else {
				$visgroupIdsHash[$name]		= $VisgroupidTable["current"]						# Create a new one
				$VisgroupidTable[$name]		= $VisgroupidTable["current"]						# Do we need a dummy variable above?
				$VisgroupidTable["current"] += 1
				
				$params = @{
					Name		= $Name
					Color		= $Color
					Visgroupid	= $VisgroupidTable[$name]
				}
				# Well of Creation
				$visgroup		= New-VmfVisgroup @params
				
				if ($parentVisgroup) {
					if (-not $parentVisgroup["classes"].Contains("visgroup")) {
						$parentVisgroup["classes"]["visgroup"] = [System.Collections.Generic.List[ordered]]::new()
					}
					$parentVisgroup["classes"]["visgroup"].Add($visgroup)
				} else {
					if ($PSBoundParameters.ContainsKey('Visgroups')) {
						# If we are here, it means that the new visgroup should belong to the one passed here
						
					}
					# TODO: Find the 'Custom' visgroup OR pass it into this function
					$Vmf["classes"]["visgroups"][0]["classes"]["visgroup"].Add($visgroup)
				}
			}
		} else {
			$visgroupIdsHash[$name]		= $VisgroupidTable["current"]							# Create a new one
			$VisgroupidTable[$name]		= $VisgroupidTable["current"]
			$VisgroupidTable["current"] += 1

			$params = @{
				Name		= $Name
				Color		= $Color
				Visgroupid	= $VisgroupidTable[$name]
			}
			$visgroup		= New-VmfVisgroup @params

			# TODO: Find the 'Custom' visgroup OR pass it into this function
			$Vmf["classes"]["visgroups"] = [System.Collections.Generic.List[ordered]]::new()
			$Vmf["classes"]["visgroups"].Add([ordered]@{
				properties	= [ordered]@{ }
				classes		= [ordered]@{ }
			})
			$Vmf["classes"]["visgroups"][0]["classes"]["visgroup"] = [System.Collections.Generic.List[ordered]]::new()
			$Vmf["classes"]["visgroups"][0]["classes"]["visgroup"].Add($visgroup)
		}

		# Essentially, the caller does not know whether this one is the value was created or read
		return $visgroupIdsHash[$name]				# Initially was meant to return the whole hash. Changed to a single value for now

	}

	END { }

}