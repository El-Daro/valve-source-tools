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

		[Parameter(Position = 2,
		Mandatory = $true)]
		$MergesCount
	)
	
	PROCESS {

		foreach ($propertyName in $LmpSection.Keys) {
			if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
				if ($VmfSection["properties"][$propertyName] -ne $LmpSection[$propertyName]) {
					$MergesCount["propsEdited"]++
					if ($propertyName.Length -gt 3 -and ($propertyName.SubString(0,2) -eq "On") -or
														($propertyName.SubString(0,3) -eq "Out")) {	
						try {														# See if property name starts with "On"
							if ($VmfSection["classes"].Contains("connections")) {	# And put it in the 'connections' class
								$VmfSection["classes"]["connections"][0]["properties"][$propertyName] = $LmpSection[$propertyName]
							} else {
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

	}

	END { }
}