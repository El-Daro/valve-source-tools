function ReportStatisticsVmf {
	Param (
		[Parameter(Position = 0,
		Mandatory = $false)]
		$CurrentLine,

		[Parameter(Position = 1,
		Mandatory = $false)]
		$LinesCount
	)

	$digitsDone		= $CurrentLine.ToString().Length + 1
	$digitsTotal	= $LinesCount.ToString().Length + 1
	$digitsTitle	= [Math]::Ceiling(($digitsTotal + $digitsDone + 27) / 2)
	$reportTitle	= "".PadLeft($digitsTitle, '-') + "LINES COUNT"	+ "".PadLeft($digitsTitle, '-')

	Write-Host "$reportTitle"
	Write-Host $("  Lines processed: {0, $digitsDone} out of {0, $digitsTotal}" -f $CurrentLine, $LinesCount)
	Write-Verbose "Processing is complete. Exiting normally"
}