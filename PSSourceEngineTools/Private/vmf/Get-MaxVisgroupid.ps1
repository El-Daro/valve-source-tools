function Get-MaxVisgroupid {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		try {
			$class			= "visgroups"
			$visgroupidMax	= 0

			if (-not $Vmf["classes"].Contains($class) -or $Vmf["classes"][$class].get_Count() -eq 0) {
				return $visgroupidMax
			}

			foreach ($vmfClassEntry in $Vmf["classes"][$class]) {
				$params = @{
					Vmf				= $vmfClassEntry
					VisgroupidMax	= $visgroupidMax
				}
				$visgroupidMax = Get-MaxVisgroupidRecursive @params
			}

		} catch {
			# Pay attention to errors
		} finally {

			#region Logging
			if (-not $Silent.IsPresent) {
				OutLog 	-Value "`nMerger | Visgroupid search: Complete"			-Path $LogFile -OneLine
				OutLog -Property "Max visgroupid"		-Value $visgroupidMax	-Path $LogFile
			}
			#endregion
		}

		return [int]$visgroupidMax
	}

	END { }
}