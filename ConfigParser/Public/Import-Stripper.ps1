using namespace System.Diagnostics

function Import-Stripper {
<#
	.SYNOPSIS
	Reads a stripper .cfg file and creates a corresponding hashtable.

	.DESCRIPTION
	Reads through a stripper .cfg file and populates an ordered hashtable with blocks that contain relative Key-Value pairs or other blocks.

	.PARAMETER Path
	Specifies the path to the stripper .cfg file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Fast
	If specified, a faster algorithm is used that only relies on regex where it is absolutely necessary 

	.INPUTS
	System.String
		You can pipe a string containing a path to this function.

	.OUTPUTS
	System.Collections.Specialized.OrderedDictionary

	.NOTES
	Empty lines and comments are ignored.
	Comments start with one of the following: `;`, `//` or `#`.
	A key cannot be empty or contain symbols `"` and `//`.
	Values formatted as "/string/" are assumed to be a regexp.
	Note that original format expects a Perl syntax regexp, which is NOT fully compatible with .NET syntax.
	No conversion on regexp is done whatsoever.
	Both key and value should be enclosed in double quotes (`" "`) and separated by whitespaces.
	Mode names are not enclosed in double quotes.
	Every mode is defined in curly brackets.
	Unlike VMF structure, in stripper configs there is usually only one mode definition with multiple blocks,
	enclosed in curly brackets.
	
	Note that key-value pairs, as well as modes, are not unique:
	it is possible to define the same key multiple times with different values
	(in practice only seen in the 'connections' class that defines outcoming script actions).
	Because of that, every dictionary entry that defines a class or a property is initialized as a Generic.List type.

	.LINK
	Export-Stripper

	.LINK
	Export-Vmf

	.LINK
	Export-Lmp

	.LINK
	Export-Vdf

	.LINK
	Export-Ini

	.LINK
	Import-Vmf

	.LINK
	Import-Lmp

	.LINK
	Import-Vdf

	.LINK
	Import-Ini

	.LINK
	Import-Csv

	.LINK
	Import-CliXml
	
	.LINK
	about_Hash_Tables
	
	.EXAMPLE
	PS> $stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
	PS> $stripperFile

		Name                           Value
		----                           -----
		properties                     {}
		modes                          {[filter, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]], […

	PS> $stripperFile["modes"]

		Name                           Value
		----                           -----
		filter                         {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictiona…
		add                            {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictiona…
		modify                         {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictiona…
	
	PS> foreach ($filter in $stripperFile["modes"]["filter"]) { $filter["properties"] }

		Name                           Value
		----                           -----
		classname                      {func_playerinfected_clip}
		classname                      {trigger_hurt_ghost}
		hammerid                       {2131720}
		hammerid                       {2131722}
		hammerid                       {2131730}

	PS> $stripperFile["modes"]["filter"].Count
	5

	PS> $stripperFile["modes"]["filter"][1]["properties"]
	
		Name                           Value
		----                           -----
		classname                      {trigger_hurt_ghost}

	PS> $stripperFile["modes"]["filter"][1]["properties"][0]
	trigger_hurt_ghost
		
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
		[string]$Path,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,
		
		[System.Management.Automation.SwitchParameter]$Fast
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
		#region Input validation
		if (-Not (Test-Path -Path $Path)) { 					# If file doesn't exist
			if (Test-Path -Path $($Path + ".cfg")) {			# See if adding '.cfg' actually helps
				$Path += ".cfg"									# If so, add the extension and proceed with the converting
				Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
			} else {
				Write-Error "$($MyInvocation.MyCommand): Could not find file '$(Get-AbsolutePath -Path $Path)'"
				Write-HostError  -ForegroundColor DarkYellow "Could not find the file. Check the spelling of the filename before using it explicitly."
				throw [System.IO.FileNotFoundException]	"Could not find file '$(Get-AbsolutePath -Path $Path)'"
			}
		} elseif ($Path -notmatch "(^(?:.+)\.cfg`"*`'*)`$") {	# If file DOES exist, see if it is not a .cfg one
			Write-Error "$($MyInvocation.MyCommand): File is not .cfg: $(Get-AbsolutePath -Path $Path)"
			Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename and its extension."
			throw [System.IO.FileFormatException] "File format is incorrect: $(Get-AbsolutePath -Path $Path)"
		}
		Write-Verbose "The input path is correct. Processing..."
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		#endregion
		
		# Had to do this due to a nasty bug with .NET being dependent on the context of where the script was launched from
		$Path = $(Get-AbsolutePath -Path $Path)
		$LogFile = $(Get-AbsolutePath -Path $LogFile)
		OutLog	-Value "`nStripper | Input received: $Path"	-Path $LogFile -OneLine

		try {
			$fileSize	= (Get-Item $Path).Length
			$fileSizeKB	= [math]::Round($fileSize / 1000)
			$digitsFileSize = $fileSizeKB.ToString().Length - 2

			if (-not $Silent.IsPresent) {
				$paramsLog	= @{
					Property	= "File size"
					Value		= $("{0,$digitsFileSize}Kb" -f $fileSizeKB)
					ColumnWidth	= 20				# Should be default
					Path		= $LogFile
				}
				OutLog @paramsLog
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
					if (-not $Silent.IsPresent) {
						OutLog -Property "Estimated lines" -Value $estimatedLines -Path $LogFile
					}

				}
				if ($lineCount -ge 10000 -and $lineCount % 10000 -eq 0) {
					$progressPercentile = "{0:N2}" -f $(($lineCount / $estimatedLines) * 100)
					$progressMessage = "{0}% ({1} / {2})" -f $progressPercentile, $lineCount, $estimatedLines
					$progressParameters = @{
						Activity         = 'Reading...'
						Status           = $progressMessage
						PercentComplete  = $progressPercentile
						CurrentOperation = 'Main Loop'
					}
					Write-Progress @progressParameters
				}
				$lineCount += 1
			}
			$sw.Stop()

			if (-not $Silent.IsPresent) {
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog					-Value "`nStripper | Reading: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Read lines"	-Value $lineCount				-Path $LogFile
				OutLog -Property "Elapsed time"	-Value $timeFormatted			-Path $LogFile
			}

			$stripperContent = $stringBuilder.ToString().Trim() -split "\n"
			if ($lineCount -lt 1) {
				Write-Verbose "The stripper .cfg file is empty."
				return $false
			} else {
				# MAIN EXIT ROUTE
				if ($Fast.IsPresent) {
					return ConvertFrom-Stripper -Lines $stripperContent -LogFile $LogFile -Silent:$Silent.IsPresent
				} else {
					return ConvertFrom-StripperRegex -Lines $stripperContent -LogFile $LogFile -Silent:$Silent.IsPresent
				}
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