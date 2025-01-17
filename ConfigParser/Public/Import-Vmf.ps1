# DONE: Rewrite helper comments from VDF to VMF
# TODO: Deliver on your promise ion the helper comments
# TODO: Cleanup

using namespace System.Diagnostics

function Import-Vmf {
<#
	.SYNOPSIS
	Reads a .vmf file and creates a corresponding hashtable.

	.DESCRIPTION
	Reads through a .vmf file and populates an ordered hashtable with blocks that contain relative Key-Value pairs or other blocks.

	.PARAMETER Path
	Specifies the path to the .vmf file. Accepts absolute and relative paths. Does NOT accept wildcards.

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
	It is up to the author of the .vmf file to properly edit it.

	.LINK
	Export-Vmf

	.LINK
	Import-Ini

	.LINK
	Import-Csv

	.LINK
	Import-CliXml
	
	.LINK
	about_Hash_Tables
	
	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\loginusers.vmf"
	PS> $vmfFile

	Name                           Value
	----                           -----
	users                          {[76561198254457678, System.Collections.Specialized.OrderedDictionary], [76561198347230468, System.Collections.Specialize…
	
	PS> $vmfFile["users"][0]["PersonaName"]
	El Daro
		
	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\loginusers.vmf"
	PS> $vmfFile["users"][0]["SkipOfflineModeWarning"]
	0
	PS> $vmfFile["users"][0]["SkipOfflineModeWarning"] = 1
	PS> $vmfFile["users"][0]["SkipOfflineModeWarning"]
	1

	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\localconfig.vmf"
	PS> $vmfFile["UserLocalConfigStore"]["system"]["EnableGameOverlay"] = 1
	PS> Export-Vmf -InputObject $vmfFile -Path ".\localconfig.vmf" -Force
#>

	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[string]$Path,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile
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
			if (Test-Path -Path $($Path + ".vmf")) {			# See if adding '.vmf' actually helps
				$Path += ".vmf"									# If so, add the extension and proceed with the converting
				Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
			} else {
				Write-Error "$($MyInvocation.MyCommand): Could not find file '$(Get-AbsolutePath -Path $Path)'"
				Write-HostError  -ForegroundColor DarkYellow "Could not find the file. Check the spelling of the filename before using it explicitly."
				throw [System.IO.FileNotFoundException]	"Could not find file '$(Get-AbsolutePath -Path $Path)'"
			}
		} elseif ($Path -notmatch "(^(?:.+)\.vmf`"*`'*)`$") {	# If file DOES exist, see if it is not a .vmf one
			Write-Error "$($MyInvocation.MyCommand): File is not .vmf: $(Get-AbsolutePath -Path $Path)"
			Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename and its extension."
			throw [System.IO.FileFormatException] "File format is incorrect: $(Get-AbsolutePath -Path $Path)"
		}
		Write-Verbose "The input path is correct. Processing..."
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		
		# Had to do this due to a nasty bug with .NET being dependent on the context of where the script was launched from
		$Path = $(Get-AbsolutePath -Path $Path)
		$LogFile = $(Get-AbsolutePath -Path $LogFile)
		# if ($LogFile) {
		# 	$logMessage = "Input file path: {0}" -f $(Get-AbsolutePath -Path $Path)
		# 	OutLog -Path $LogFile -Value $logMessage
		# }

		# $stringBuilder	= [System.Text.StringBuilder]::new(256)
		try {
			# TODO: Clean this shit up!
			# NOTE: The reading part seems to work fine
			# $vmfContent = Get-Content $Path

			# Gonna make this shit fast, boi
			$fileSize	= (Get-Item $Path).Length
			$fileSizeKB	= [math]::Round($fileSize / 1000)
			$digitsFileSize = $fileSizeKB.ToString().Length - 2
			Write-Host -ForegroundColor Magenta -NoNewLine	"      File size: "
			Write-Host -ForegroundColor Cyan	$("{0,$digitsFileSize}Kb" -f $fileSizeKB)
			if ($LogFile) {
				$logMessage = "      File size: {0,$digitsFileSize}Kb" -f $fileSizeKB
				OutLog -Path $LogFile -Value $logMessage
			}
			$stringBuilder	= [System.Text.StringBuilder]::new(256)
			$lineCount = 0
			$sw = [Stopwatch]::StartNew()
			foreach ($line in [System.IO.File]::ReadLines($Path)) {
				[void]$stringBuilder.AppendLine($line)

				if ($lineCount -eq 1000) {
					# ReCalculate average line length
					$averageLineLength = ($stringBuilder.ToString().Split("`n") | ForEach-Object { $_.Length } | Measure-Object -Average).Average
					$estimatedLines = [math]::Floor($fileSize / $averageLineLength)
					Write-Host -ForegroundColor Magenta -NoNewLine	"Estimated lines: "
					Write-Host -ForegroundColor Cyan				$("{0}" -f $estimatedLines)
					if ($LogFile) {
						$logMessage = "Estimated lines: {0}" -f $estimatedLines
						OutLog -Path $LogFile -Value $logMessage
					}

					# break
				}
				if ($lineCount -ge 10000 -and $lineCount % 10000 -eq 0) {
					$progressPercentile = "{0:N2}" -f $(($lineCount / $estimatedLines) * 100)
					$progressMessage = "{0}% ({1} / {2})" -f $progressPercentile, $lineCount, $estimatedLines
					$progressParameters = @{
						Activity         = 'Reading'
						Status           = $progressMessage
						PercentComplete  = $progressPercentile
						CurrentOperation = 'Main Loop'
					}
					Write-Progress @progressParameters
				}
				<#
				# if ($lineCount -gt 1000 -and $lineCount % 10000 -eq 0) {
				# 	# ReCalculate average line length
				# 	$averageLineLength = ($stringBuilder.ToString().Split("`n") | ForEach-Object { $_.Length } | Measure-Object -Average).Average

				# 	# Estimate total lines
				# 	$estimatedLines = [math]::Floor($fileSize / $averageLineLength)

				# 	# Write-Host -ForegroundColor Magenta "      File size: $fileSize"
				# 	# Write-Host -ForegroundColor Magenta "Estimated lines: $estimatedLines"
				# }
				#>

				$lineCount += 1
			}
			$sw.Stop()
			# Write-Host -ForegroundColor DarkYellow			"Reading complete"
			# if ($estimatedLines) {
			# 	Write-Host -ForegroundColor Magenta -NoNewLine	"Estimated lines: "
			# 	Write-Host -ForegroundColor Cyan				$("{0,6}" -f $estimatedLines)
			# }
			Write-Host -ForegroundColor DarkYellow			"Reading: Complete"
			Write-Host -ForegroundColor Magenta -NoNewLine	"     Read lines: "
			Write-Host -ForegroundColor Cyan				$("{0}" -f $lineCount)
			Write-Host -ForegroundColor Magenta -NoNewLine	"   Elapsed time: "
			Write-Host -ForegroundColor Cyan				$("{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds)
			if ($LogFile) {
				$logMessage  = "`nReading: Complete `n"
				$logMessage += "     Read lines: {0} `n" -f $lineCount
				$logMessage += "   Elapsed time: {0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog -Path $LogFile -Value $logMessage
			}

			$vmfContent = $stringBuilder.ToString().Trim() -split "\n"
			# $vmfContent = $stringBuilder.ToString() -split '\r?\n'
			# $vmfContent2 = "string 1 `n string 2 `n string 3" -split '\r?\n'
			# Write-Host $vmfContent.GetType()
			if ($lineCount -lt 1) {
				Write-Verbose "The .vmf file is empty."
				return $false
			} else {
				# MAIN EXIT ROUTE
				# return ConvertFrom-Vmf -Lines $vmfContent
				# return ConvertFrom-Vmf -Lines $( $stringBuilder.ToString() -split '\r?\n' )
				return ConvertFrom-Vmf -Lines $vmfContent -LogFile $LogFile
			}
		} catch [System.IO.FileNotFoundException], [System.IO.IOException] {
			Write-HostError -ForegroundColor Red -NoNewline		"  File ("
			Write-HostError -ForegroundColor Cyan -NoNewline	"`"$(Get-AbsolutePath -Path $Path)`""
			Write-HostError -ForegroundColor Red				") is corrupted or doesn't exist!"
			Write-HostError -ForegroundColor DarkYellow			" Check the spelling of the filename before using it explicitly."
			Throw $_.Exception
		} catch {
			Throw $_.Exception
		}
	}

	END {}
}