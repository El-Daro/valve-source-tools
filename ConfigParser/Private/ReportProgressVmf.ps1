function ReportProgressVmf {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$CurrentLine,

		[Parameter(Position = 1,
		Mandatory = $true)]
		$LinesCount,

		[Parameter(Position = 2,
		Mandatory = $false)]
		$EstimatedMilliseconds,

		[Parameter(Position = 3,
		Mandatory = $false)]
		$ElapsedMilliseconds,

		[Parameter(Position = 4,
		Mandatory = $false)]
		$Activity = "Processing... "
	)

	# $digitsTotal	= $LinesCount.ToString().Length + 1
	# $digitsTitle	= [Math]::Ceiling(($digitsTotal + 21) / 2)
	# $reportTitle	= "".PadLeft($digitsTitle, '-') + "LINES COUNT"	+ "".PadLeft($digitsTitle, '-')

	# Write-Host "$reportTitle"
	# Write-Host $("  Lines processed: {0, $digitsTotal}" -f $LinesCount)
	# Write-Verbose "Processing is complete. Exiting normally"

	# $intProgressPercentile =($CurrentLine / $LinesCount) * 100
	# if ($intProgressPercentile -gt 100) {
	# 	$intProgressPercentile = 100
	# }
	$progressPercentile = "{0:N2}" -f $(($CurrentLine / $LinesCount) * 100)
	if ([int]$progressPercentile -gt 100) {
		[int]$progressPercentile = 100
	}
	if ($null -ne $EstimatedMilliseconds -and $null -ne $ElapsedMilliseconds) {
		$estimatedMinutes	= [math]::Floor($EstimatedMilliseconds / 60000)
		$estimatedSeconds	= [math]::Floor((($EstimatedMilliseconds / 60000) - $estimatedMinutes) * 60)
		
		$leftMilliseconds	= $EstimatedMilliseconds - $ElapsedMilliseconds
		if ($leftMilliseconds -lt 0) {
			$leftMilliseconds = 0
		}
		$leftMinutes		= [math]::Floor($leftMilliseconds / 60000)
		$leftSeconds		= [math]::Floor((($leftMilliseconds / 60000) - $leftMinutes) * 60)
		
		$progressMessage	= "{0}% | Lines: {1}/{2} | Estimated time: {3}m {4}s | Estimated time left: {5}m {6}s" -f
			$progressPercentile, $CurrentLine, $LinesCount, $estimatedMinutes, $estimatedSeconds, $leftMinutes, $leftSeconds
	} else {
		$progressMessage	= "{0}% ({1} / {2})" -f
			$progressPercentile, $CurrentLine, $LinesCount
	}

	$progressParameters = @{
		Activity         = $Activity
		Status           = $progressMessage
		PercentComplete  = $progressPercentile
		CurrentOperation = 'MainLoop'
	}

	Write-Progress @progressParameters

	# for ($i = 1; $i -le 100; $i++ ) {
	# 	$progressParameters = @{
	# 		Activity         = 'Parsing'
	# 		Status           = 'Progress->'
	# 		PercentComplete  = $i
	# 		CurrentOperation = 'MainLoop'
	# 	}
	# 	# Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i
	# 	Write-Progress @progressParameters
	# 	Start-Sleep -Milliseconds 100
	# }
}

# $PSStyle.Progress.MaxWidth = 80
# $PSStyle.Progress.View = "Minimal"
# ReportCountVdf