# Done: Come up with a way of copying "connections" correctly
# TODO: Research possible names 'connections' could have

using namespace System.Diagnostics

function Copy-LmpSection {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$VmfSection,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$LmpSection,

		# [Parameter(Position = 2,
		# Mandatory = $false)]
		# $Visgroups,

		# [Parameter(Position = 3,
		# Mandatory = $false)]
		# $VisIdPointer,

		# [Parameter(Position = 4,
		# Mandatory = $false)]
		# $VisColor,

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount

		# [Parameter(Position = 6,
		# Mandatory = $true)]
		# [ref]$LmpEditedExists,

		# [Parameter(Position = 7,
		# Mandatory = $true)]
		# $VisgroupsTableTemporaryName
	)
	
	PROCESS {

		$isEdited = $false
		foreach ($propertyName in $LmpSection.Keys) {
			if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
				if ($VmfSection["properties"][$propertyName] -ne $LmpSection[$propertyName]) {
					$MergesCount["propsEdited"]++

					if (-not $isEdited) {
						$isEdited = $true
					}
					
					if ($propertyName.Length -gt 3 -and ($propertyName.SubString(0,2) -eq "On") -or
														($propertyName.SubString(0,3) -eq "Out")) {	
						try {														# See if property name starts with "On"
							if ($VmfSection["classes"].Contains("connections")) {	# And put it in the 'connections' class
								$VmfSection["classes"]["connections"][0]["properties"][$propertyName] = $LmpSection[$propertyName]
							} else {
								# TODO: See if this logic is correct. Should probably create connections here
								$VmfSection["properties"][$propertyName] = $LmpSection[$propertyName]
							}
						} catch {
							# Do nothing
							Write-Host -ForegroundColor DarkYellow "Failed to copy connections. Hammerid: $($LmpSection["hammerid"])"
						}
					} else {
						$VmfSection["properties"][$propertyName] = $LmpSection[$propertyName]
					}
				} else {
					$MergesCount["propsSkipped"]++
				}
			}
		}

		<#
		if ($isEdited) {
			if (-not $VisIdPointer.Contains("edited")) {
				# If it doesn't exist, create it
				$params	= @{
					# Is it needed?
					VisgroupidTable	= $VisgroupidTable
					Name			= "edited"
					ParentName		= "lmp"
				}
				$VisgroupidTable["edited"] = New-VmfVisgroupIDPointer @params
			}

			if (-not $VisgroupsTableTemporaryName.Contains("edited")) {
				$params	= @{
					Vmf				= $Vmf				# Pass the whole thing, because 'visgroup' class should be the standard
					VisgroupidTable	= $VisgroupidTable	# Why? Just because there is max value? | Yes
					Name			= $visgroupNameMain	# "LMP" | Case-sensitive?..
					# What else do we need?
				}
				# Get - because we know it exists and we get the value
				# Find - because we need to verify it exists
				# New - because it's a wrapper concept
				$visgroupsTableTemporaryName[$visgroupNameMain] = New-VmfVisgroupPrototype @params		# BLACKBOX
			}


			$params = @{
				VmfSection	= $VmfSection
				Color		= $VisColor
				VisgroupID	= $VisIdPointer["edited"]
			}
			$success = New-VmfEditor @params

			if ($success -and -not $VisgroupidTable.Contains("lmpEdited")) {
				$VisgroupidTable["lmpEdited"]	= $VisIdPointer["edited"]
				$VisgroupidTable["current"]		+= 1
			}
		}
		#>

		return $isEdited
	}

	END { }
}