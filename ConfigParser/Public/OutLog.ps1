# TODO: Expand

function OutLog {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[string]$Value,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$Path,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$Extension = ".log",

		[System.Management.Automation.SwitchParameter]$Force,

		[System.Management.Automation.SwitchParameter]$PassThru,
		
		[System.Management.Automation.SwitchParameter]$NoNewLine,

		$FailSafePath = "./logs/stats.log"
	)

	$params = @{
		Value		= $Value
		Path		= $Path
		Force		= $Force
		PassThru	= $PassThru
		NoNewLine	= $NoNewLine
	}
	Write-Log @params
	# Write-Log @params -Force:$Force -PassThru:$PassThru -NoNewLine:$NoNewLine
	# Write-Log -Value $Value -Path $Path -Force:$Force.IsPresent -PassThru:$PassThru.IsPresent -NoNewLine:$NoNewLine.IsPresent

	# if ($Path) {
	# 	if (-not (Test-Path -Path $($Path) -IsValid) -and
	# 			 (Test-Path -Path $($Path + $Extension) -IsValid)) {
	# 		Write-Verbose "$($MyInvocation.MyCommand): Log file path is invalid: $(Get-AbsolutePath -Path $Path)"
	# 		if ($PassThru) {
	# 			$Value		# Honoring -PassThru here
	# 		}
	# 		$Path = $FailSafePath
	# 	}
	# 	Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
	# 	Write-Verbose "Writing to the normal output: $(Get-AbsolutePath -Path $Path)"
		
	# 	if ($NoNewLine) {
	# 		Add-Content -Path $Path -Value $Value -NoNewLine
	# 	} else {
	# 		Add-Content -Path $Path -Value $Value
	# 	}
	# }

	# if ((-Not $Path -and (-Not $DebugPreference -eq 'Continue')) -or
	# 		$PassThru) {
	# 	# If none are specified or 'PassThru' is used, the content is returned as a string
	# 	return $Value
	# }
}