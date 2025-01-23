function Export-Lmp {
	<#
		.SYNOPSIS
		Converts a hashtable into a binary .lmp file and outputs it in a file.
	
		.DESCRIPTION
		Converts a hashtable into a single string, formatted specifically for .lmp files.
		This function is designed to work with ordered and unordered hashtables.
	
		.PARAMETER InputObject
		The object to convert. It can be ordered or unordered hashtable. Must contain 'header' and 'data' hashtables inside.
	
		.PARAMETER Path
		Specifies the path to the output .lmp file. Accepts absolute and relative paths. Does NOT accept wildcards.

		.PARAMETER AsText
		If specified, output file is written as plain text without header
		
		.PARAMETER Silent
		If specified, suppresses console output

		.PARAMETER Force
		If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.
	
		.PARAMETER PassThru
		If specified, returns the resulting .lmp formatted string even if `-Path` parameter was used.
	
		.INPUTS
		System.Collections.IDictionary
			Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.
	
		.OUTPUTS
		System.String
			Only returns string if both `-AsText` and `-PassThru` are specified

		.NOTES
		Input must contain 'header' and 'data' hashtables inside.
		'Data' hashtable should contain other hashtable entries — sections.
		Sections describe sets of parameters (key-value pairs).
		Note that keys are not necessarily unique. 

		.LINK
		Import-Lmp

		.LINK
		Import-Vmf

		.LINK
		Import-Vdf

		.LINK
		Import-Ini
		
		.LINK
		Export-Vmf
		
		.LINK
		Export-Vdf
	
		.LINK
		Export-Ini
	
		.LINK
		Export-Csv
	
		.LINK
		Export-CliXml
		
		.LINK
		about_Hash_Tables
		
		.EXAMPLE
		PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
		PS> $lmpFile["data"]["hammerid-2935785"]["angles"][0] = "45 120 0"
		PS> Export-Lmp -InputObject $lmpFile -Path ".\c5m3_cemetery_d_1.lmp"

	#>
	
		[CmdletBinding()]
		Param (
			[Parameter(Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true)]
			[System.Collections.IDictionary]$InputObject,
	
			[Parameter(Position = 1,
			Mandatory = $true)]
			[string]$Path,

			[Parameter(Position = 2,
			Mandatory = $false)]
			[string]$LogFile,

			[System.Management.Automation.SwitchParameter]$Silent,

			[System.Management.Automation.SwitchParameter]$AsText,
			
			[System.Management.Automation.SwitchParameter]$Force,
	
			[System.Management.Automation.SwitchParameter]$PassThru,
	
			[Parameter(DontShow)]
			[string]$DebugOutput = ".\output_debug.lmp"
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
				if (-not ($InputObject.Contains("header") -and
				$InputObject["header"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]))) {
					# Header will be recreated
					# Write-Debug "Input hashtable does not contain header"
					Write-Error "Input hashtable does not contain header"
					Throw "$($MyInvocation.MyCommand): $($PSItem)"
				}
				if ((-not $InputObject.Contains("data") -and
				$InputObject["data"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]))) {
					# Write-Debug "InputObject does not contain data hashtable"
					# Write-Debug "InputObject is assumed to be only containing data"
					Write-Error "InputObject does not contain data hashtable"
					Throw "$($MyInvocation.MyCommand): $($PSItem)"
				}
			}
			#endregion
			$LogFile = $(Get-AbsolutePath -Path $LogFile)		# Just a precaution
	
			$lmp = ConvertTo-Lmp -Lmp $InputObject -LogFile $LogFile -Silent:$Silent.IsPresent -AsText:$AsText.IsPresent
	
			$params = @{
				Content			= $lmp
				Path			= $Path
				Force 			= $Force.IsPresent
				PassThru		= $PassThru.IsPresent
				Extension		= ".lmp"
				AsByteStream	= $(-not $AsText.IsPresent)
				DebugOutput		= $DebugOutput
				Silent			= $Silent.IsPresent
			}
			Out-Config @params
	
			if (-not $Silent.IsPresent) {
				OutLog -Value "`nExporting file: Complete `n" -Path $LogFile -OneLine
			}
		}
	
		END { }
	}