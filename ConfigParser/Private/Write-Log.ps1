# This function is essentially just a wrapper for the Add-Content cmdlet
# Refer to Out-Log for the main logging function 

function Write-Log {
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

	$pathInvalid = $false

	if ($Path -and (-not (Test-Path -Path $($Path)				-IsValid) -and
						 (Test-Path -Path $($Path + $Extension) -IsValid))) {
		Write-Verbose "$($MyInvocation.MyCommand): Log file path is invalid: $(Get-AbsolutePath -Path $Path)"
		Write-Verbose "$($MyInvocation.MyCommand): Writing to a failsafe path"
		$pathInvalid = $true
	}
	if ($pathInvalid) {
		$Path = $FailSafePath
	}
	Write-Debug		"$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
	Write-Verbose	"$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
	
	if ($NoNewLine) {
		Add-Content -Path $Path -Value $Value -NoNewLine
	} else {
		Add-Content -Path $Path -Value $Value
	}

	if ((-Not $Path -and (-Not $DebugPreference -eq 'Continue')) -or
			$PassThru) {
		# If none are specified or 'PassThru' is used, the content is returned as a string
		return $Value
	}
}