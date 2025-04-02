using namespace System.Diagnostics

function New-VmfVisgroup {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $false)]
		$Name = "Custom",

		[Parameter(Position = 1,
		Mandatory = $false)]
		$Color = "128 128 128",

		[Parameter(Position = 2,
		Mandatory = $false)]
		$Visgroupid = 1
	)
	
	PROCESS {
	
		# $class			= "visgroup"

		# Creating new visgroup:
		$visgroupBlock			= [ordered]@{
			properties			= [ordered]@{};
			classes				= [ordered]@{}
		}

		# Properties
		$visgroupBlock["properties"]["name"] = [Collections.Generic.List[string]]::new()
		$visgroupBlock["properties"]["name"].Add($Name)
		$visgroupBlock["properties"]["color"] = [Collections.Generic.List[string]]::new()
		$visgroupBlock["properties"]["color"].Add($Color)
		$visgroupBlock["properties"]["visgroupid"] = [Collections.Generic.List[string]]::new()
		$visgroupBlock["properties"]["visgroupid"].Add($Visgroupid)
		# $VisgroupidTable["current"]++

		# Classes
		# $visgroupBlock["classes"][$class] = [Collections.Generic.List[ordered]]::new()
		# $visgroupBlock["classes"][$class].Add([ordered]@{
		# 	properties	= [ordered]@{ }
		# 	classes		= [ordered]@{ }
		# })


		# <properties>
		# 	"name" "Custom"
		# 	"color" "128 128 128"
		# 	"visgroupid" "1"
		# <classes>
		#	-

		return $visgroupBlock
	}

	END { }
}