function ReportStatistics {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$LinesCount,

		[Parameter(Position = 1,
		Mandatory = $true)]
		$LinesFaulty
	)

	$digitsTotal	= $LinesCount.ToString().Length + 1
	$digitsValid	= $($LinesCount - $LinesFaulty).ToString().Length + 1
	$digitsInvalid	= $LinesFaulty.ToString().Length + 1
	$digitsTitle	= [Math]::Ceiling(($digitsTotal	+ $digitsValid	+ $digitsInvalid + 21) / 2)
	$reportTitle	= "".PadLeft($digitsTitle, '-') + "LINES COUNT"	+ "".PadLeft($digitsTitle, '-')

	Write-Verbose "$reportTitle"
	Write-Verbose $("  Total: {0, $digitsTotal}  |  Valid: {1, $digitsValid} | Ivalid: {2, $digitsInvalid}" -f
								$LinesCount,	$($LinesCount - $LinesFaulty),			$LinesFaulty)
	Write-Verbose "Processing is complete. Exiting normally"
}