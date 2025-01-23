# Q: What happens, if you check for Path that is not provided?
# A: Works as if Path was non-existent, although it is an empty string in the end, which is something you should keep in mind

function Out-Config {
<#
	.SYNOPSIS
	Outputs an INI-, VDF-, VMF-, LMP- or TXT-formatted file.

	.DESCRIPTION
	Takes an INI-, VDF-, VMF-, LMP- or TXT-formatted string and either outputs it in an `.ini/.vdf/.vmf/.lmp/.txt` file,
	if the `-Path` parameter was specified, or returns the string back to the caller.
	
	.PARAMETER Content
	An INI-, VDF-, VMF-, LMP- or TXT-formatted string.

	.PARAMETER Path
	Specifies the path to the output file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER AsByteStream
	If specified, outputs a binary file

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting formatted string even if `-Path` parameter was used. 

	.PARAMETER Silent
	If specified, suppresses console output
#>
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$Content,

		[Parameter(Position = 1)]
		[string]$Path,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[string]$Extension,

		[System.Management.Automation.SwitchParameter]$AsByteStream,

		[System.Management.Automation.SwitchParameter]$Force,

		[System.Management.Automation.SwitchParameter]$PassThru,
		
		[System.Management.Automation.SwitchParameter]$Silent,
		
		[string]$DebugOutput = "./output_debug"
	)

	$winPowerShell = $false
	if ($PSVersionTable.PSVersion.Major -lt 6) {
		$winPowerShell = $true
	}

	# We want to print the debug output first in case something breaks afterwards
	if ($DebugPreference -eq 'Continue') {		# Debug output is always written, if specified
		Write-Verbose "Writing to the debug output: $(Get-AbsolutePath -Path $DebugOutput)"
		if ($null -ne $Content) {
			New-Item -Name $DebugOutput -Value $Content -Force
		}
	}
	# This here is a giant mess, quite honestly. But it's the price you pay to make it flexible.
	if ($Path) {											# Check if the output file already exists (we don't want to overwrite it)
		if ( (Test-Path -Path $Path) -and -not $Force.IsPresent ) {	# First check for the provided Path
			Write-Error "$($MyInvocation.MyCommand): The file '$(Get-AbsolutePath -Path $Path)' already exists."
			return $false
		} elseif ( (Test-Path -Path $($Path + $Extension)) -and -not $Force.IsPresent ) {	# Then see if adding extension changes anything
			Write-Error "$($MyInvocation.MyCommand): The file '$(Get-AbsolutePath -Path $($Path + $Extension))' already exists."
			return $false
		} elseif ($Path -notmatch $(Get-ExtensionRegex -Extension $Extension)) {
			if ((Split-Path -Path $Path -Leaf).ToString() -match "[.].*$") {
				# If we are here, it means that a wrong extension was provided
				Write-Error "$($MyInvocation.MyCommand): File is not $($Extension): $(Get-AbsolutePath -Path $Path)"
				Write-Host -ForegroundColor DarkYellow "Check the file extension."
				return $false
			} else {
				# If we are here, it means that no extension was provided
				if (Test-Path -Path $($Path + $Extension) -IsValid) {
					$Path += $Extension
					Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
				} else {
					# If we are here, it means something has gone real wrong with the inputs
					Write-Error "$($MyInvocation.MyCommand): Path is invalid: $(Get-AbsolutePath -Path $Path)"
					return $false
				}
			}
		} elseif (-not (Test-Path -Path $($Path) -IsValid)) {
			Write-Error "$($MyInvocation.MyCommand): Path is invalid: $(Get-AbsolutePath -Path $Path)"
			if ($PassThru.IsPresent) {
				$Content		# Honoring -PassThru here
			}
			return $false
		}
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		Write-Verbose "Writing to the normal output: $(Get-AbsolutePath -Path $Path)"

		if ($Silent.IsPresent) {
			if (-not $AsByteStream.IsPresent) {
				New-Item -Path $Path -Value $Content -Force:$Force.IsPresent | Out-Null
			} else {
				if ($winPowerShell) {
					# PS5-
					Set-Content -Path $Path -Value $Content -Encoding Binary -Force:$Force.IsPresent | Out-Null
				} else {
					# PS6.0+
					Set-Content -Path $Path -Value $Content -AsByteStream -Force:$Force.IsPresent | Out-Null
				}
				# [System.IO.File]::WriteAllBytes($Path, $Content)
			}
		} else {
			if (-not $AsByteStream.IsPresent) {
				New-Item -Path $Path -Value $Content -Force:$Force.IsPresent
			} else {
				if ($winPowerShell) {
					# PS5-
					Set-Content -Path $Path -Value $Content -Encoding Binary -Force:$Force.IsPresent
				} else {
					# PS6.0+
					Set-Content -Path $Path -Value $Content -AsByteStream -Force:$Force.IsPresent
				}
				# [System.IO.File]::WriteAllBytes($Path, $Content)
			}
		}
	}
	if ($null -ne $Content -and
		((-Not $Path -and (-Not $DebugPreference -eq 'Continue')) -or
			$PassThru.IsPresent)) {
		# If none are specified or 'PassThru' is used, the content is returned as a string
		return $Content
	}
}