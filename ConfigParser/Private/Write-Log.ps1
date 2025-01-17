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
		
		[System.Management.Automation.SwitchParameter]$NoNewLine,
		
		[System.Management.Automation.SwitchParameter]$Force,
		
		[System.Management.Automation.SwitchParameter]$NoFailSafe,

		$FailSafePath = "./logs/stats.log"
	)

	$pathInvalid = $false

	if ($Path -and (-not (Test-Path -Path $($Path)		-IsValid) -and
						 (Test-Path -Path $($Path + $Extension) -IsValid)
				   )
		) {
		Write-Verbose "$($MyInvocation.MyCommand): Log file path is invalid: $(Get-AbsolutePath -Path $Path)"
		Write-Verbose "$($MyInvocation.MyCommand): Writing to a failsafe path"
		$pathInvalid = $true
	} elseif ([string]::IsNullOrWhiteSpace($Path)) {
		Write-Verbose "$($MyInvocation.MyCommand): Log file path is not provided"
		Write-Verbose "$($MyInvocation.MyCommand): Writing to a failsafe path"
		$pathInvalid = $true
	}
	if ($pathInvalid) {
		if ($NoFailSafe.IsPresent) {
			return
		}
		$Path	= $FailSafePath
		if (-not $(Test-Path -Path $FailSafePath)) {
			New-Item -Path $FailSafePath -Force | Out-Null
		}
	}
	Write-Debug		"$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
	Write-Verbose	"$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
	
	if ($NoNewLine.IsPresent) {
		Add-Content -Path $Path -Value $Value -Force:$Force -NoNewLine
	} else {
		Add-Content -Path $Path -Value $Value -Force:$Force
	}
}