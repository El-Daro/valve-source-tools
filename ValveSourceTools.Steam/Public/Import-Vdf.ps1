using namespace System.Diagnostics

function Import-Vdf {
<#
	.SYNOPSIS
	Reads a .vdf file and creates a corresponding hashtable.

	.DESCRIPTION
	Reads through a .vdf file and populates an ordered hashtable with blocks that contain relative Key-Value pairs or other blocks.

	.PARAMETER Path
	Specifies the path to the .vdf file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.INPUTS
	System.String
		You can pipe a string containing a path to this function.

	.OUTPUTS
	System.Collections.Specialized.OrderedDictionary

	.NOTES
	An empty line is ignored.
	A key cannot be empty or contain any of the following symbols: `[`, `]`, `;`, `#` and `=`.
	A value should be enclosed in double quotes (`" "`).
	If a key provided with no corresponding value, a block is expected to follow next.
	If there is no opening bracket after said key, an exception is raised.
	Poor syntax can sometimes be forgiven, but in this case the function might yield unexpected results.
	It is up to the author of the .vdf file to properly edit it.

	.LINK
	Export-Vdf

	.LINK
	Import-Ini

	.LINK
	Import-Csv

	.LINK
	Import-CliXml
	
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
		[string]$Path
	)

	BEGIN {
		#region PREPARATIONS
		# Since this module is written directly in PowerShell,
		# the Common Parameters do not propagate, if this funciton is called from another module.
		# The code described in "PREPARATIONS" section is meant to fix this behaviour.
		# It is not necessary for any functions called from inside this module.
		# For more on this matter, see issue #4568 on GitHub: https://github.com/PowerShell/PowerShell/issues/4568 
		$prefVars = @{
			'ErrorActionPreference'	= 'ErrorAction'
			'DebugPreference'		= 'Debug'
			'VerbosePreference'		= 'Verbose'
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
						# Which asks for input every time it encounters a Write-Debug cmdlet
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
		if (-Not (Test-Path -Path $Path)) { 					# If file doesn't exist
			if (Test-Path -Path $($Path + ".vdf")) {			# See if adding '.vdf' actually helps
				$Path += ".vdf"									# If so, add the extension and proceed with the converting
				Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
			} else {
				Write-Error "$($MyInvocation.MyCommand): Could not find file '$(Get-AbsolutePath -Path $Path)'"
				Write-HostError  -ForegroundColor DarkYellow "Could not find the file. Check the spelling of the filename before using it explicitly."
				throw [System.IO.FileNotFoundException]	"Could not find file '$(Get-AbsolutePath -Path $Path)'"
			}
		} elseif ($Path -notmatch "(^(?:.+)\.vdf`"*`'*)`$") {	# If file DOES exist, see if it is not a .vdf one
			Write-Error "$($MyInvocation.MyCommand): File is not .vdf: $(Get-AbsolutePath -Path $Path)"
			Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename and its extension."
			throw [System.IO.FileFormatException] "File format is incorrect: $(Get-AbsolutePath -Path $Path)"
		}
		Write-Verbose "The input path is correct. Processing..."
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"

		# $stringBuilder	= [System.Text.StringBuilder]::new(256)
		try {
			# $vdfContent = Get-Content $Path

			# Gonna make this shit fast, boi
			$fileSize = (Get-Item $Path).Length
			Write-Host -ForegroundColor Magenta "      File size: $fileSize"
			$stringBuilder	= [System.Text.StringBuilder]::new(256)
			$stringBuilder2	= [System.Text.StringBuilder]::new(256)
			$lineCount = 0
			$sw = [Stopwatch]::StartNew()
			[void]$stringBuilder2.AppendLine("Fucking work")
			[void]$stringBuilder2.AppendLine("Stupid shit")
			[void]$stringBuilder2.AppendLine("Bastard")
			foreach ($line in [System.IO.File]::ReadLines($Path)) {
				[void]$stringBuilder.AppendLine($line)

				if ($lineCount -eq 1000) {
					# ReCalculate average line length
					$averageLineLength = ($stringBuilder.ToString().Split("`n") | ForEach-Object { $_.Length } | Measure-Object -Average).Average
					# $averageLineLength = ($stringBuilder.ToString() -split '\r?\n' | ForEach-Object { $_.Length } | Measure-Object -Average).Average

					# Estimate total lines
					$estimatedLines = [math]::Floor($fileSize / $averageLineLength)

					# Write-Host -ForegroundColor Magenta "      File size: $fileSize"
					Write-Host -ForegroundColor Magenta "Estimated lines: $estimatedLines"

					break
				}
				if ($lineCount -ge 1000 -and $lineCount % 100 -eq 0) {
					$progressPercentile = "{0:N2}" -f $(($lineCount / $estimatedLines) * 100)
					$progressMessage = "$progressPercentile % ( $lineCount / $estimatedLines )"
					$progressParameters = @{
						Activity         = 'Reading'
						Status           = $progressMessage
						PercentComplete  = $progressPercentile
						CurrentOperation = 'FirstLoop'
					}
					Write-Progress @progressParameters
				}
				# if ($lineCount -gt 1000 -and $lineCount % 10000) {
				# 	# ReCalculate average line length
				# 	$averageLineLength = ($stringBuilder.ToString().Split("`n") | ForEach-Object { $_.Length } | Measure-Object -Average).Average

				# 	# Estimate total lines
				# 	$estimatedLines = [math]::Floor($fileSize / $averageLineLength)

				# 	# Write-Host -ForegroundColor Magenta "      File size: $fileSize"
				# 	# Write-Host -ForegroundColor Magenta "Estimated lines: $estimatedLines"
				# }

				$lineCount += 1
			}
			$sw.Stop()
			Write-Host -ForegroundColor DarkYellow	"Reading complete"
			Write-Host -ForegroundColor Magenta -NoNewLine	"Estimated lines: "
			Write-Host -ForegroundColor Cyan				$("{0,6}" -f $estimatedLines)
			Write-Host -ForegroundColor Magenta -NoNewLine	"     Read lines: "
			Write-Host -ForegroundColor Cyan				$("{0,6}" -f $lineCount)
			Write-Host -ForegroundColor DarkYellow	"   Elapsed time: $($sw.Elapsed.Minutes)m $($sw.Elapsed.Seconds)s $($sw.Elapsed.Milliseconds)ms"

			$vdfContent = $stringBuilder.ToString().Trim("`n") -split "\n"
			# $vdfContent = $stringBuilder.ToString() -split '\r?\n'
			# $vdfContent2 = "string 1 `n string 2 `n string 3" -split '\r?\n'
			# Write-Host $vdfContent.GetType()
			if ($lineCount -lt 1) {
				Write-Verbose "The .vdf file is empty."
				return $false
			} else {
				# MAIN EXIT ROUTE
				# return ConvertFrom-Vdf -Lines $vdfContent
				# return ConvertFrom-Vdf -Lines $( $stringBuilder.ToString() -split '\r?\n' )
				return ConvertFrom-Vdf -Lines $vdfContent
			}
		} catch [System.IO.FileNotFoundException], [System.IO.IOException] {
			Write-HostError -ForegroundColor Red -NoNewline "  File ("
			Write-HostError -ForegroundColor Cyan -NoNewline "`"$(Get-AbsolutePath -Path $Path)`""
			Write-HostError -ForegroundColor Red ") is corrupted or doesn't exist!"
			Write-HostError -ForegroundColor DarkYellow " Check the spelling of the filename before using it explicitly."
			Throw $_.Exception
		} catch {
			Throw $_.Exception
		}
	}

	END {}
}