function Export-Stripper {
<#
	.SYNOPSIS
	Converts a hashtable into Stripper's .cfg file format string and outputs it in a file, if specified.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for stripper .cfg files.
	This function is designed to work with ordered and unordered hashtables.
	
	Stipper:Source is a Source engine plugin that is used to modify maps on the servers without requiring clients to redownload them.
	You can see links to description and source code in the LINKS section.

	.PARAMETER InputObject
	The object to convert. It can be ordered or unordered hashtable.

	.PARAMETER Path
	Specifies the path to the output stripper .cfg file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting stripper .cfg formatted string even if `-Path` parameter was used.

	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.

	.OUTPUTS
	System.String
		Note that by default this function returns only the stripper .cfg formatted string. If you want to output to a file instead,
		use the `-Path` parameter.

	.LINK
	Import-Stripper

	.LINK
	Import-Lmp

	.LINK
	Import-Vmf

	.LINK
	Import-Vdf

	.LINK
	Import-Ini

	.LINK
	Export-Lmp
	
	.LINK
	Export-Vmf
	
	.LINK
	Export-Vdf

	.LINK
	Export-Ini

	.LINK
	https://forums.alliedmods.net/showthread.php?t=39439

	.LINK
	https://www.bailopan.net/stripper/

	.LINK
	https://github.com/alliedmodders/stripper-source/tree/master
	
	.EXAMPLE
	PS> $stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
	PS> $stripperFile["modes"]["modify"][0]["modes"]["replace"][0]["properties"]

		Name                           Value
		----                           -----
		spawnflags                     {257}
		angles                         {7 15 0}
		origin                         {5498.43 -124.58 18.3698}

	PS> $stripperFile["modes"]["modify"][0]["modes"]["replace"][0]["properties"]["spawnflags"].GetType()

		IsPublic IsSerial Name                                     BaseType
		-------- -------- ----                                     --------
		True     True     List`1                                   System.Object

	PS> $stripperFile["modes"]["modify"][0]["modes"]["replace"][0]["properties"]["spawnflags"][0] = 1
	PS> $stripperFile["modes"]["modify"][0]["modes"]["replace"][0]["properties"]

		Name                           Value
		----                           -----
		spawnflags                     {1}
		angles                         {7 15 0}
		origin                         {5498.43 -124.58 18.3698}
		
	PS> Export-Stripper -InputObject $stripperFile -Path ".\c5m3_cemetery_1.cfg"

	.EXAMPLE
	PS> $stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
	PS> $stripperFile["modes"]["modify"][0]["modes"]["replace"][0]["properties"]["spawnflags"][0] = 1
	PS> Export-Stripper -InputObject $stripperFile -Path ".\c5m3_cemetery_1.cfg"
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

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Force,

		[System.Management.Automation.SwitchParameter]$PassThru,

		[Parameter(DontShow)]
		[string]$DebugOutput = ".\output_debug.cfg"
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
		$LogFile	= $(Get-AbsolutePath -Path $LogFile)		# Just a precaution

		$stripper	= ConvertTo-Stripper -Stripper $InputObject -LogFile $LogFile -Silent:$Silent.IsPresent

		$params		= @{
			Content			= $stripper
			Path			= $Path
			Force 			= $Force.IsPresent
			PassThru		= $PassThru.IsPresent
			Extension		= ".cfg"
			DebugOutput		= $DebugOutput
			Silent			= $Silent.IsPresent
		}
		Out-Config @params

		if (-not $Silent.IsPresent) {
			Out-Log -Value "`nStripper | Exporting file: Complete `n" -Path $LogFile -OneLine
		}
	}

	END { }
}