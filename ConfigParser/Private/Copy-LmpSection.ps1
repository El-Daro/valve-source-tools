# TODO: Come up with a way of copying "connections" correctly

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
		[ref]$PropsEdited,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		foreach ($propertyName in $LmpSection.Keys) {
			if ($propertyName -ne "hammerid") {				# We don't need to copy matched hammerid
				if ($VmfSection[$propertyName] -ne $LmpSection[$propertyName]) {
					$PropsEdited.Value++
				}
				$VmfSection[$propertyName] = $LmpSection[$propertyName]
			}
		}

	}

	END { }
}