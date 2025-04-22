using namespace System.Diagnostics

function Add-VmfVisgroup {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$Visgroup,

		[Parameter(Position = 1,
		Mandatory = $false)]
		$Name = "Custom",

		[Parameter(Position = 2,
		Mandatory = $false)]
		$Color = "128 128 128",

		[Parameter(Position = 3,
		Mandatory = $false)]
		$Visgroupid = 1
	)
	
	PROCESS {

		$success = $false
		try {
			if (-not $visgroup["classes"].Contains("visgroup") -or -not $visgroup["classes"]["visgroup"].get_Count() -gt 0) {
				$visgroup["classes"]["visgroup"] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
			}
			$params = @{
				Name		= $Name
				Color		= $Color
				Visgroupid	= $Visgroupid
			}
			$newVisgroup	= New-VmfVisgroup @params
			$visgroup["classes"]["visgroup"].Add($newVisgroup)
			$success = $true
		} catch {
			Write-Debug "$($MyInvocation.MyCommand):  Failed to add '$Name' visgroup. Continuing as is"
		}
		# Consider returning the visgroup section
		return $success
	}

	END { }
}