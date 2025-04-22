# insert: Specifies any additional key value pairs to insert
# NOTE: This is a pretty fucked up function, so here's a rundown:
#		1. Determine whether or not Stripper's prop is a 'connection'
#			- If no, go to 4
#		2. Determine whether or not VMF block already has 'connections' class
#			- If yes, go to 4
#		3. Create connections class and add the key-value pair(s)
#		4. Determine whether or not the key is present
#			- If not, add it
#			- If yes, see if the value is present
#				- If yes, skip
#				- If no, add value to the key's Generic.List

using namespace System.Diagnostics

function ProcessStripperModInsert {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfClassEntry,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Modify,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount
	)
	
	PROCESS {

		foreach ($stripperProp in $Modify["properties"].Keys) {
			if ($stripperProp -eq "hammerid") {
				$key = "id"
			} else {
				$key = $stripperProp
			}
			$IsConnections = $false
			if ($key.Length -gt 3 -and ($key.SubString(0,2) -eq "On") -or
									   ($key.SubString(0,3) -eq "Out")) {
				$IsConnections = $true
			}

			$stripperValues = $Modify["properties"][$stripperProp]
			foreach ($value in $stripperValues) {
				#region Shitcode
				if ($IsConnections) {												# If the property being inserted is a connection
					if (-not $vmfClassEntry["classes"].Contains("connections")) {	# And we don't have the class
																					# Create it
						try {
							$vmfClassEntry["classes"]["connections"] = [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
							$vmfClassEntry["classes"]["connections"].Add([ordered]@{
								properties	= [ordered]@{ }
								classes		= [ordered]@{ }
							})	# Since we created it, we don't need to check whether the prop exists
							$vmfClassEntry["classes"]["connections"][0]["properties"][$key] = [Collections.Generic.List[string]]::new()
							$vmfClassEntry["classes"]["connections"][0]["properties"][$key].Add($value)
						} catch {
								# Do nothing
							Write-Host -ForegroundColor DarkYellow "Failed to insert connection: `"$key`" `"$value`""
						}
					} else {	# Okay, so we DO have 'connections' class
						if (-not $vmfClassEntry["classes"]["connections"][0]["properties"].Contains($key)) {		# If prop does not exist - create it
							$vmfClassEntry["classes"]["connections"][0]["properties"][$key] = [Collections.Generic.List[string]]::new()
						} elseif ($vmfClassEntry["classes"]["connections"][0]["properties"][$key].Contains($value)) {
							# If prop name exists, see if value is already there
							continue
						}
						$vmfClassEntry["classes"]["connections"][0]["properties"][$key].Add($value)
					}
				} else {
					if (-not $vmfClassEntry["properties"].Contains($key)) {
						$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
					} elseif ($vmfClassEntry["properties"][$key].Contains($value)) {
						continue
					}
					$vmfClassEntry["properties"][$key].Add($value)
				}
				#endregion

				$MergesCount["modifyInserted"]++
				$MergesCount["propsNew"]++

			}
		}

	}

	END { }
}