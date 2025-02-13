using namespace System.Diagnostics

function EstimateMergerInputLmp {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 1,
		Mandatory = $false)]
		$LmpHammerIdOffset = 9,

		[Parameter(Position = 2,
		Mandatory = $false)]
		$LmpClassnameOffset = 10
	)
	
	PROCESS {

		# $lmpHammerIdOffset	= 9
		# $lmpClassnameOffset	= 10
		$counterLmp			= @{
			hammerid	= 0
			classname	= 0
			unknown		= 0
			total		= $Lmp["data"].get_Count()
		}
		
		foreach ($lmpSection in $Lmp["data"].Keys) {
			if ($lmpSection.SubString(0,$LmpHammerIdOffset) -eq "hammerid-") {
				$counterLmp["hammerid"]++
			} elseif ($lmpSection.SubString(0,$LmpClassnameOffset) -eq "classname-") {
				$counterLmp["classname"]++
			} else {
				$counterLmp["unknown"]++
				Write-Host -ForegroundColor DarkYellow "This is an error"
				Write-Host $lmpSection
			}
			# $counterLmp["total"]++
		}

		return $counterLmp
	}

	END { }
}