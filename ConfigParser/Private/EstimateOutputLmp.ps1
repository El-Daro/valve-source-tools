function EstimateOutputLmp {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	$sectionCounter	= 0
	$estimatedLines = 0
	try {

		$estimatedSections	= $Lmp["data"].Count
		foreach ($section in $Lmp["data"].Keys) {
			$estimatedLines += $Lmp["data"][$section].Keys.Count
			$estimatedLines += 2		#  Counting the brackets here
			$sectionCounter++
		}

	} catch {
		Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	} finally {
		if (-not $Silent.IsPresent) {
			if ($estimatedLines -gt 0) {
				OutLog								-Value "`nOutput estimation: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Lines estimate"			-Value $estimatedLines		-Path $LogFile
				OutLog -Property "Sections estimate"		-Value $estimatedSections	-Path $LogFile
			} else {
				OutLog	-Value "`nFailed to estimate lines count"	-Path $LogFile -OneLine
			}
		}

	}

	return [ordered]@{ lines = $estimatedLines; sections = $estimatedSections }
}