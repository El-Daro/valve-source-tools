# match: Matches all entities that have the listed model and classname. You can use regular expressions (//) for any key values here.
# replace: Replaces the values of any properties that have the same key name. In this example, "prop_physics_multiplayer" will become "hostage_entity."
# delete: Deletes any properties matching both the key name and the value string. The value string may have regular expressions (//). In this example, the model property of the trash can is being removed.
# insert: Specifies any additional key value pairs to insert. Here, an arbitrary scaling value is added to the entity.

using namespace System.Diagnostics

function ProcessStripperModify {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Modify,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$CounterStripper,

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		# 1. Match
		if ($Modify["modes"]["match"][0].Count -eq 0) {
			$MergesCount["modifySkipped"]++
			return $False
		}
:mainL	foreach ($vmfClass in $Vmf["classes"].Keys) {
:vmfClassL	foreach ($vmfClassEntry in $Vmf["classes"][$vmfClass]) {
				$matchCounter = 0
				#region MATCH
:stripperMainL	foreach ($stripperProp in $Modify["modes"]["match"][0]["properties"].Keys) {
					if ($stripperProp -eq "hammerid") {
						$key = "id"
					} else {
						$key = $stripperProp
					}
					$stripperValues = $Modify["modes"]["match"][0]["properties"][$stripperProp]
					foreach ($value in $stripperValues) {
						# The new code for the matches
						if ($value.Length -gt 2 -and $value[0] -eq "/" -and $value[$value.Length - 1] -eq "/") {
							$stripperValueRegex = $value.SubString(1, $value.Length - 2) 
							if ($vmfClassEntry["properties"].Contains($key)) {
								try {
									foreach ($vmfPropValue in $vmfClassEntry["properties"][$key]) {
										if ($vmfPropValue -match $stripperValueRegex) {
											$matchCounter++
											break
										}
									}
								} catch {
									Write-Debug "$($MyInvocation.MyCommand):  Failed to do a regex check"
								}
							} else {
								break stripperMainL
							}
						} else {
							if ($vmfClassEntry["properties"].Contains($key) -and
								$vmfClassEntry["properties"][$key].Contains($value)) {
								$matchCounter++	
							# $vmfSectionFound = $true
							} else {
								break stripperMainL
							}
						}
					}
				}
				#endregion
				# If all the props in the 'match' section have matched
				if ($matchCounter -eq $Modify["modes"]["match"][0]["properties"].Count) {
					#region REPLACE
					if ($Modify["modes"]["replace"].get_Count() -gt 0) {
						foreach ($stripperProp in $Modify["modes"]["replace"][0]["properties"].Keys) {
							if ($stripperProp -eq "hammerid") {
								$key = "id"
							} else {
								$key = $stripperProp
							}
							$stripperValues = $Modify["modes"]["replace"][0]["properties" ][$stripperProp]
							foreach ($value in $stripperValues) {
								# The new code for the matches
								if ($vmfClassEntry["properties"].Contains($key)) {
									$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
									$vmfClassEntry["properties"][$key].Add($value)
									$MergesCount["modifyReplaced"]++
									$MergesCount["propsEdited"]++
								} else {
									break
								}
							}
						}
					}
					#endregion

					#region DELETE
					if ($Modify["modes"]["delete"].get_Count() -gt 0) {
						foreach ($stripperProp in $Modify["modes"]["delete"][0]["properties"].Keys) {
							if ($stripperProp -eq "hammerid") {
								$key = "id"
							} else {
								$key = $stripperProp
							}
							$stripperValues = $Modify["modes"]["delete"][0]["properties"][$stripperProp]
							foreach ($value in $stripperValues) {
								# The new code for the matches
								if ($vmfClassEntry["properties"].Contains($key) -and
									$vmfClassEntry["properties"][$key].Contains($value)) {
									$vmfClassEntry["properties"].Remove($key)
									$MergesCount["modifyDeleted"]++
									$MergesCount["propsDeleted"]++
								}
							}
						}
					}
					#endregion

					#region INSERT
					if ($Modify["modes"]["insert"].get_Count() -gt 0) {
						foreach ($stripperProp in $Modify["modes"]["insert"][0]["properties"].Keys) {
							if ($stripperProp -eq "hammerid") {
								$key = "id"
							} else {
								$key = $stripperProp
							}
							$stripperValues = $Modify["modes"]["insert"][0]["properties"][$stripperProp]
							foreach ($value in $stripperValues) {
								# The new code for the matches
								if ($vmfClassEntry["properties"].Contains($key) -and
									$vmfClassEntry["properties"][$key].Contains($value)) {
									break
								} else {
									$vmfClassEntry["properties"][$key] = [Collections.Generic.List[string]]::new()
									$vmfClassEntry["properties"][$key].Add($value)
									$MergesCount["modifyInserted"]++
									$MergesCount["propsNew"]++
								}
							}
						}
					}
					#endregion

					$MergesCount["modify"]++
				}
			}
		}

		return $true

	}

	END { }
}