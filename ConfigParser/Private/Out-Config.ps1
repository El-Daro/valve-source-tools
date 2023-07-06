# Q: What happens, if you check for Path that is not provided?
# A: Works as if Path was non-existent, although it is an empty string in the end, which is something you should keep in mind

function Out-Config {
<#
	.SYNOPSIS
	Outputs an INI- or VDF-formatted string

	.DESCRIPTION
	Takes an INI- or VDF-formatted string and either outputs it in an `.ini/.vdf` file, if the `-Path` parameter was specified,
	or returns the string back to the caller.
	
	.PARAMETER Content
	An INI- or VDF-formatted string.

	.PARAMETER Path
	Specifies the path to the output .vdf file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting .vdf formatted string even if `-Path` parameter was used. 
#>
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string]$Content,

		[Parameter(Position = 1)]
		[string]$Path,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[string]$Extension,

		[Parameter(Position = 3)]
		[System.Management.Automation.SwitchParameter]$Force = $False,

		[Parameter(Position = 4)]
		[System.Management.Automation.SwitchParameter]$PassThru = $False,

		[Parameter(Position = 5)]
		[string]$DebugOutput = "./output_debug"
	)

	# We want to print the debug output first in case something breaks afterwards
	if ($DebugPreference -eq 'Continue') {		# Debug output is always written, if specified
		Write-Verbose "Writing to the debug output: $(Get-AbsolutePath -Path $DebugOutput)"
		New-Item -Name $DebugOutput -Value $Content -Force
	}
	# This here is a giant mess, quite honestly. But it's the price you pay to make it flexible.
	if ($Path) {											# Check if the output file already exists (we don't want to overwrite it)
		if ( (Test-Path -Path $Path) -and -not $Force ) {	# First check for the provided Path
			Write-Error "$($MyInvocation.MyCommand): The file '$(Get-AbsolutePath -Path $Path)' already exists."
			return $false
		} elseif ( (Test-Path -Path $($Path + $Extension)) -and -not $Force ) {	# Then see if adding extension changes anything
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
			if ($PassThru) {
				$Content		# Honoring -PassThru here
			}
			return $false
		}
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		Write-Verbose "Writing to the normal output: $(Get-AbsolutePath -Path $Path)"
		if ($Force) {
			New-Item -Name $Path -Value $Content -Force
		} else {
			New-Item -Name $Path -Value $Content
		}
	}
	if ((-Not $Path -and (-Not $DebugPreference -eq 'Continue')) -or
			$PassThru) {
		# If none are specified or 'PassThru' is used, the content is returned as a string
		return $Content
	}
}