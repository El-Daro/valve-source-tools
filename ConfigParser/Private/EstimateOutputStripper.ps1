# TODO: Make a better approximation

function EstimateOutputStripper {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[System.Collections.IDictionary]$Stripper,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	$estimatedProps	= 0
	$estimatedModes	= 0
	$estimatedLines = 0
	try {

		# TODO: Make a better approximation 
		$estimatedModes	= $Stripper["modes"]["filter"].Count +
						  $Stripper["modes"]["add"].Count +
						  $Stripper["modes"]["modify"].Count
		$estimatedLines	= $Stripper["modes"]["filter"].Count * 3 + 1 +
						  $Stripper["modes"]["add"].Count * 3 + 1 +
						  $Stripper["modes"]["modify"].Count * 4 * 4 +
						  $Stripper["modes"]["modify"].Count * 2 + 1
		foreach ($mode in $Stripper["modes"]["modify"]) {
			# $estimatedLines += $mode["modes"]["match"].Count * 3 + 1 +
			# 				   $mode["modes"]["replace"].Count * 3 + 1 +
			# 				   $mode["modes"]["delete"].Count * 3 + 1 +
			# 				   $mode["modes"]["insert"].Count * 3 + 1
			# $estimatedLines += 2		#  Counting the brackets here
			$estimatedModes++
			foreach ($subMode in $mode["modes"]["match"]) {
				$estimatedModes++
				$estimatedLines += $subMode["properties"].Count * 3
				$estimatedProps += $subMode["properties"].Count * 3
			}
			foreach ($subMode in $mode["modes"]["replace"]) {
				$estimatedModes++
				$estimatedLines += $subMode["properties"].Count * 3
				$estimatedProps += $subMode["properties"].Count * 3
			}
			foreach ($subMode in $mode["modes"]["delete"]) {
				$estimatedModes++
				$estimatedLines += $subMode["properties"].Count * 3
				$estimatedProps += $subMode["properties"].Count * 3
			}
			foreach ($subMode in $mode["modes"]["insert"]) {
				$estimatedModes++
				$estimatedLines += $subMode["properties"].Count * 3
				$estimatedProps += $subMode["properties"].Count * 3
			}
		}

	} catch {
		Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	} finally {
		if (-not $Silent.IsPresent) {
			if ($estimatedLines -gt 0) {
				OutLog								-Value "`nOutput estimation: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Lines estimate"		-Value $estimatedLines				-Path $LogFile
				OutLog -Property "Sections estimate"	-Value $estimatedModes				-Path $LogFile
			} else {
				OutLog	-Value "`nFailed to estimate lines count"	-Path $LogFile -OneLine
			}
		}

	}

	return [ordered]@{ lines = $estimatedLines; modes = $estimatedModes }
}