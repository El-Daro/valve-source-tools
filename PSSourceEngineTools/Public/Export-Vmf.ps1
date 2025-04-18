# TODO: Cleanup

function Export-Vmf {
<#
	.SYNOPSIS
	Converts a hashtable into a .vmf file format string and outputs it in a file, if specified.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vmf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER InputObject
	The object to convert. It can be ordered or unordered hashtable.

	.PARAMETER Path
	Specifies the path to the output .vmf file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting .vmf formatted string even if `-Path` parameter was used.

	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.

	.OUTPUTS
	System.String
		Note that by default this function returns only the .vmf formatted string. If you want to output to a file instead,
		use the `-Path` parameter.

	.LINK
	Import-Vmf

	.LINK
	Import-Lmp

	.LINK
	Import-Stripper

	.LINK
	Import-Vdf

	.LINK
	Import-Ini
	
	.LINK
	Export-Lmp

	.LINK
	Export-Stripper
	
	.LINK
	Export-Vdf

	.LINK
	Export-Ini

	.LINK
	Export-Csv

	.LINK
	Export-CliXml
	
	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
	PS> $vmfFile

		Name                           Value
		----                           -----
		properties                     {}
		classes                        {[world, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]], [entity, System.Collecti…
	
	PS> $vmfFile["classes"]

		Name                           Value
		----                           -----
		world                          {System.Collections.Specialized.OrderedDictionary}
		entity                         {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, System.Collections…
		cameras                        {System.Collections.Specialized.OrderedDictionary}

	PS> $vmfFile["classes"]["world"][0]["properties"]

		Name                           Value
		----                           -----
		id                             {1}
		timeofday                      {2}
		startmusictype                 {1}
		skyname                        {sky_l4d_c5_1_hdr}
		musicpostfix                   {BigEasy}
		maxpropscreenwidth             {-1}
		detailvbsp                     {detail.vbsp}
		detailmaterial                 {detail/detailsprites_overgrown}
		mapversion                     {5359}
		comment                        {Decompiled by BSPSource v1.4.6.1 from c5m3_cemetery}
		classname                      {worldspawn}

	PS> $vmfFile["classes"]["entity"].Count	
	6648

	PS> Export-Vmf -InputObject $vmfFile -Path ".\c5m3_cemetery_d_1.vmf"

	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
	PS> $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"][0] = 0
	PS> Export-Vmf -InputObject $vmfFile -Path ".\c5m3_cemetery_d_1.vmf"
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
		[bool]$Fast = $false,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Force = $False,

		[System.Management.Automation.SwitchParameter]$PassThru = $False,

		[Parameter(DontShow)]
		[string]$DebugOutput = ".\output_debug.vmf"
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

		$vmf = ConvertTo-Vmf -Vmf $InputObject -LogFile $LogFile -Fast $Fast -Silent:$Silent.IsPresent

		$params = @{
			Content			= $vmf
			Path			= $Path
			Force 			= $Force.IsPresent
			PassThru		= $PassThru.IsPresent
			Extension		= ".vmf"
			DebugOutput		= $DebugOutput
			Silent			= $Silent.IsPresent
		}
		Out-Config @params

		if (-not $Silent.IsPresent) {
			OutLog -Value "`nVMF | Exporting file: Complete `n" -Path $LogFile -OneLine
		}
	}

	END { }
}