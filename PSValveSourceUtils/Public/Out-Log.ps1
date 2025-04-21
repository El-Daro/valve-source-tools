function Out-Log {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $false)]
		[string]$Property = "",

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$Value = "",

		[Parameter(Position = 2,
		Mandatory = $false)]
		$ColumnWidth = 25,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[string]$Path = "",

		[Parameter(Position = 4,
		Mandatory = $false)]
		[string]$Extension = ".log",

		[System.Management.Automation.SwitchParameter]$NoFile,

		[System.Management.Automation.SwitchParameter]$NoConsole,
		
		[System.Management.Automation.SwitchParameter]$NoNewLine,
		
		[System.Management.Automation.SwitchParameter]$OneLine,
		
		[System.Management.Automation.SwitchParameter]$NoFailSafe,

		[System.Management.Automation.SwitchParameter]$Force
	)

	# Construct the line
	if (-not [string]::IsNullOrEmpty($Property)) {
		$Property = "{0,$($ColumnWidth)}: " -f $Property
	}
	$line = "{0}{1}" -f $Property, $Value

	# Print the line to the console
	if (-not $NoConsole.IsPresent) {
		if ($OneLine.IsPresent) {
			Write-Host -ForegroundColor DarkYellow "$line"
		} else {
			Write-Host -ForegroundColor Magenta -NoNewline	$("{0}"	-f $Property)
			Write-Host -ForegroundColor Cyan				$("{0}"	-f $Value)
		}
	}

	# Send the line to the file
	if (-not $NoFile.IsPresent -and $false -ne $logFile) {
		$params = @{
			Value		= $line
			Path		= $Path
			Extension	= $Extension
			NoNewLine	= $NoNewLine
			Force		= $Force
			NoFailSafe	= $NoFailSafe
		}
		Write-Log @params
	}
}