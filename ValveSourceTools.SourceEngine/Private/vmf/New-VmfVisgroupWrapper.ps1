using namespace System.Diagnostics

function New-VmfVisgroupWrapper {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfSection,

		[Parameter(Position = 1,
		Mandatory = $false)]
		$Name = "Custom",

		[Parameter(Position = 2,
		Mandatory = $false)]
		$Color = "128 128 128",

		[Parameter(Position = 3,
		Mandatory = $false)]
		[System.Collections.IDictionary]$VisgroupidTable = @{ custom = 1 },

		[System.Management.Automation.SwitchParameter]$MarkTemporary
	)
	
	PROCESS {

		$success		= $false
		$targetVisgroup	= $false
		try {
			$params = @{
				VmfSection	= $VmfSection
				MatchSet	= @{ name = $Name }
				ClassName	= "visgroup"
			}
			$targetVisgroup	= Get-VmfSection @params

			if ($targetVisgroup -and $targetVisgroup["properties"].Contains("visgroupid") -and 
									 $targetVisgroup["properties"]["visgroupid"].get_Count() -gt 0) {
				$visgroupidTable[$Name] = $targetVisgroup["properties"]["visgroupid"][0]
			# } elseif ($MarkTemporary.IsPresent) {
			# 	return $false
			} else {
				$params = @{
					Visgroup	= $VmfSection
					Name		= $Name
					Color		= $Color
					Visgroupid	= $visgroupidTable["current"]
				}
				$success		= Add-VmfVisgroup @params
				if ($success) {
					$visgroupidTable[$Name]		= $visgroupidTable["current"]
					$visgroupidTable["current"]	+= 1
					$params = @{
						VmfSection	= $VmfSection
						MatchSet	= @{ name = $Name }
						ClassName	= "visgroup"
					}
					$targetVisgroup	= Get-VmfSection @params
					if ($MarkTemporary.IsPresent) {
						$targetVisgroup["properties"]["temporary"] = [Collections.Generic.List[string]]::new()
						$targetVisgroup["properties"]["temporary"].Add("1")
					}
				}
			}
		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to instantiate '$Name' visgroup. Continuing as is"
		}

		return $targetVisgroup
	}

	END { }
}