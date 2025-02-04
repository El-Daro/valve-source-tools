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

	$estimatedOutput = @{
		lines	= 0;
		modes	= 0;
		props	= 0;
		filter	= 0;
		add		= 0;
		modify	= 0
	}
	try {

		#region Rough approximation
		# With the right coefficients might be worth it on large inputs
		# $estimatedOutput["props"] = $Stripper["modes"]["filter"].Count +
		# 				 			$Stripper["modes"]["add"].Count
		# $estimatedOutput["modes"] = $Stripper["modes"]["filter"].Count +
		# 							$Stripper["modes"]["add"].Count +
		# 							$Stripper["modes"]["modify"].Count
		# $estimatedOutput["lines"] = $Stripper["modes"]["filter"].Count * 3 + 1 +
		# 							$Stripper["modes"]["add"].Count * 3 + 1 +
		# 						#   $Stripper["modes"]["modify"].Count * 4 * 4 +
		# 							$Stripper["modes"]["modify"].Count * 2 + 1
		#endregion
		
		if ($Stripper["modes"]["filter"].Count -gt 0) {
			$estimatedOutput["lines"]++
			foreach ($mode in $Stripper["modes"]["filter"]) {
				$estimatedOutput["lines"]	+= $mode["properties"].Count + 2
				$estimatedOutput["props"]	+= $mode["properties"].Count
				$estimatedOutput["modes"]	+= 1
				$estimatedOutput["filter"]	+= 1
			}
		}

		if ($Stripper["modes"]["add"].Count -gt 0) {
			$estimatedOutput["lines"]++
			foreach ($mode in $Stripper["modes"]["add"]) {
				$estimatedOutput["lines"] += $mode["properties"].Count + 2
				$estimatedOutput["props"] += $mode["properties"].Count
				$estimatedOutput["modes"] += 1
				$estimatedOutput["add"]	+= 1
			}
		}

		if ($Stripper["modes"]["modify"].Count -gt 0) {
			$estimatedOutput["lines"]++
			foreach ($mode in $Stripper["modes"]["modify"]) {
				# Rough approximation
				# $estimatedLines += $mode["modes"]["match"].Count * 3 + 1 +
				# 				   $mode["modes"]["replace"].Count * 3 + 1 +
				# 				   $mode["modes"]["delete"].Count * 3 + 1 +
				# 				   $mode["modes"]["insert"].Count * 3 + 1
				# $estimatedLines += 2		#  Counting the brackets here
				$estimatedOutput["modes"]	+= 1
				$estimatedOutput["modify"]	+= 1
				$estimatedOutput["lines"]	+= 2
				if ($mode["modes"]["match"].Count -gt 0) {
					$estimatedOutput["lines"]++
					foreach ($subMode in $mode["modes"]["match"]) {
						$estimatedOutput["modes"]++
						$estimatedOutput["lines"] += $subMode["properties"].Count + 2
						$estimatedOutput["props"] += $subMode["properties"].Count
					}
				}

				if ($mode["modes"]["replace"].Count -gt 0) {
					$estimatedOutput["lines"]++
					foreach ($subMode in $mode["modes"]["replace"]) {
						$estimatedOutput["modes"]++
						$estimatedOutput["lines"] += $subMode["properties"].Count + 2
						$estimatedOutput["props"] += $subMode["properties"].Count
					}
				}

				if ($mode["modes"]["delete"].Count -gt 0) {
					$estimatedOutput["lines"]++
					foreach ($subMode in $mode["modes"]["delete"]) {
						$estimatedOutput["modes"]++
						$estimatedOutput["lines"] += $subMode["properties"].Count + 2
						$estimatedOutput["props"] += $subMode["properties"].Count
					}
				}

				if ($mode["modes"]["insert"].Count -gt 0) {
					$estimatedOutput["lines"]++
					foreach ($subMode in $mode["modes"]["insert"]) {
						$estimatedOutput["modes"]++
						$estimatedOutput["lines"] += $subMode["properties"].Count + 2
						$estimatedOutput["props"] += $subMode["properties"].Count
					}
				}
			}
		}

	} catch {
		Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	} finally {
		if (-not $Silent.IsPresent) {
			if ($estimatedOutput["lines"] -gt 0) {
				OutLog					-Value "`nStripper | Output estimation: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Lines estimate"		-Value $estimatedOutput["lines"]	-Path $LogFile
				OutLog -Property "Sections estimate"	-Value $estimatedOutput["modes"]	-Path $LogFile
				OutLog -Property "Properties estimate"	-Value $estimatedOutput["props"]	-Path $LogFile
			} else {
				OutLog	-Value "`nFailed to estimate lines count"	-Path $LogFile -OneLine
			}
		}

	}

	return $estimatedOutput
}