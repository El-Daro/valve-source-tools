function ReportLine {
	# A simple function that reports the file and line at which the execution of the script stopped
	Param(
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string]$Path,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[string]$CurrentLine,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[int]$LinesCount
	)

	$digits = $LinesCount.ToString().Length + 1
	Write-HostError -ForegroundColor Magenta -NoNewLine	$("  File {0,$($digits)}`t" -f ":")
	Write-HostError -ForegroundColor Cyan				"$Path"
	Write-HostError -ForegroundColor Magenta -NoNewLine	"  Line"
	Write-HostError -ForegroundColor Cyan	-NoNewLine	$("{0,$digits}" -f $LinesCount)
	Write-HostError -ForegroundColor Magenta -NoNewLine	":`t"
	Write-HostError -ForegroundColor DarkGray			"$CurrentLine"
}