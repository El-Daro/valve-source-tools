using namespace System.Diagnostics

function Add-VmfEditor {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$VmfSection,

		[Parameter(Position = 1,
		Mandatory = $false)]
		$Color = "128 128 128",

		[Parameter(Position = 2,
		Mandatory = $false)]
		$VisgroupID = "127",

		[Parameter(Position = 3,
		Mandatory = $false)]
		$VisgroupShown = "1",

		[Parameter(Position = 4,
		Mandatory = $false)]
		$VisgroupAutoShown = "1",

		[Parameter(Position = 5,
		Mandatory = $false)]
		$Logicalpos = "[0 0]"
	)
	
	PROCESS {

		# <properties>
		# 	"color" "128 128 128"
		# 	"visgroupid" "55"
		# 	"visgroupshown" "1"
		# 	"visgroupautoshown" "1"
		# 	"logicalpos" "[0 0]"
		# <classes>
		#	-
	
		$class = "editor"
		
		if (-not $vmfSection["classes"].Contains($class)) {
			$vmfSection["classes"][$class] = [System.Collections.Generic.List[ordered]]::new()
			$vmfSection["classes"][$class].Add([ordered]@{
				properties	= [ordered]@{ }
				classes		= [ordered]@{ }
			})
		}
		
		# $vmfSection["classes"][$class][0]["properties"].Add("color", $Color)
		$vmfSection["classes"][$class][0]["properties"]["color"] = [Collections.Generic.List[string]]::new()
		$vmfSection["classes"][$class][0]["properties"]["color"].Add([string]$Color)
		$vmfSection["classes"][$class][0]["properties"]["visgroupid"] = [Collections.Generic.List[string]]::new()
		$vmfSection["classes"][$class][0]["properties"]["visgroupid"].Add([string]$VisgroupID)
		$vmfSection["classes"][$class][0]["properties"]["visgroupshown"] = [Collections.Generic.List[string]]::new()
		$vmfSection["classes"][$class][0]["properties"]["visgroupshown"].Add([string]$VisgroupShown)
		$vmfSection["classes"][$class][0]["properties"]["visgroupautoshown"] = [Collections.Generic.List[string]]::new()
		$vmfSection["classes"][$class][0]["properties"]["visgroupautoshown"].Add([string]$VisgroupAutoShown)
		$vmfSection["classes"][$class][0]["properties"]["logicalpos"] = [Collections.Generic.List[string]]::new()
		$vmfSection["classes"][$class][0]["properties"]["logicalpos"].Add([string]$Logicalpos)

	}

	END { }
}