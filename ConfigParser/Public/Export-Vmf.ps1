# TODO: Cleanup

function Export-Vmf {
<#
	.SYNOPSIS
	Converts a hashtable into a .vdf file format string and outputs it in a file, if specified.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vdf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER InputObject
	The object to convert. It can be ordered or unordered hashtable.

	.PARAMETER Path
	Specifies the path to the output .vdf file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting .vdf formatted string even if `-Path` parameter was used.

	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.

	.OUTPUTS
	System.String
		Note that by default this function returns only the .vdf formatted string. If you want to output to a file instead,
		use the `-Path` parameter.

	.LINK
	Import-Vdf

	.LINK
	Export-Ini

	.LINK
	Export-Csv

	.LINK
	Export-CliXml
	
	.LINK
	about_Hash_Tables
	
	.EXAMPLE
	PS> $vdfFile = Import-Vdf -Path ".\loginusers.vdf"
	PS> $vdfFile

	Name                           Value
	----                           -----
	users                          {[76561198254457678, System.Collections.Specialized.OrderedDictionary], [76561198347230468, System.Collections.Specialize…
	
	PS> $vdfFile["users"][0]["PersonaName"]
	El Daro
		
	.EXAMPLE
	PS> $vdfFile = Import-Vdf -Path ".\loginusers.vdf"
	PS> $vdfFile["users"][0]["SkipOfflineModeWarning"]
	0
	PS> $vdfFile["users"][0]["SkipOfflineModeWarning"] = 1
	PS> $vdfFile["users"][0]["SkipOfflineModeWarning"]
	1

	.EXAMPLE
	PS> $vdfFile = Import-Vdf -Path ".\localconfig.vdf"
	PS> $vdfFile["UserLocalConfigStore"]["system"]["EnableGameOverlay"] = 1
	PS> Export-Vdf -InputObject $vdfFile -Path ".\localconfig.vdf" -Force
#>

	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[System.Collections.IDictionary]$InputObject,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$Path,

		[System.Management.Automation.SwitchParameter]$Force = $False,

		[System.Management.Automation.SwitchParameter]$PassThru = $False,

		[Parameter(DontShow)]
		[string]$DebugOutput = ".\output_debug.vmf",

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[bool]$Fast = $False
	)

	BEGIN {
		#region PREPARATION
		# Since this module is written directly in PowerShell,
		# the Common Parameters do not propagate, if this funciton is called from another module.
		# The code described in "PREPARATIONS" section is meant to fix this behaviour.
		# It is not necessary for any functions called from inside this module.
		# For more on this matter, see issue #4568 on GitHub: https://github.com/PowerShell/PowerShell/issues/4568 
		$prefVars = @{
			'ErrorActionPreference' = 'ErrorAction'
			'DebugPreference' = 'Debug'
			'VerbosePreference' = 'Verbose'
		}

		foreach ($entry in $prefVars.GetEnumerator()) {
			if (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) {
				$callersVar = $PSCmdlet.SessionState.PSVariable.Get($entry.Key)
				if ($null -ne $callersVar) {
					if ($entry.Key -eq 'DebugPreference' -and
						($callersVar.Value -eq 'Continue' -or $callersVar.Value -eq 'Inquire')
						) {
						# This is necessary for Windows PowerShell (up to 5.1.3)
						# When the common parameter '-Debug' is used, Windows PowerShell sets the $DebugPreference to 'Inquire'
						# Which asks for input every time it encounters a Write-Debug cmdlet. We don't want that
						$DebugPreference = 'Continue'
						# Write-Debug "Preference variable $($entry.Key) was set to Continue"
					} else {
						Set-Variable -Name $callersVar.Name -Value $callersVar.Value -Force -Confirm:$false -WhatIf:$false
						# Write-Debug "Preference variable $($entry.Key) was set to $($callersVar.Value)"
					}
				}
			} elseif ($PSBoundParameters.ContainsKey('Debug')) {
				$DebugPreference = 'Continue'
			}
		}
		#endregion
	}

	PROCESS {
		#region INPUT EVALUATION
		if ($InputObject -and
			$InputObject.GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]) ) {
			Write-Debug "Input: $($InputObject.GetType().FullName)"
		}
		#endregion
		$LogFile = $(Get-AbsolutePath -Path $LogFile)		# Just a precaution

		$vmf = ConvertTo-Vmf -Vmf $InputObject -LogFile $LogFile -Fast $Fast

		$params = @{
			Content		= $vmf
			Path		= $Path
			Force 		= $Force
			PassThru	= $PassThru
			Extension	= ".vmf"
			DebugOutput	= $DebugOutput
		}
		Out-Config @params

		OutLog -Value "`nExporting file: Complete `n" -Path $LogFile -OneLine
	}

	END { }
}