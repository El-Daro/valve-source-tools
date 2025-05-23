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
	Empty lines and comments are ignored (a comment can only sit on its own line and starts with `//`).
	A key cannot be empty or contain symbols `"` and `//`.
	Both key and value should be enclosed in double quotes (`" "`) and separated by one whitespace.
	Class names are not enclosed in double quotes.
	Every class is defined in curly brackets.
	VMF files have a recursive structure; each class may contain properties and other classes.
	
	Note that key-value pairs, as well as classes, are not unique:
	it is possible to define the same key multiple times with different values
	(in practice only seen in the 'connections' class that defines outcoming script actions).
	Having the same class definition multiple times, however, is very common.
	In fact, a typical VMF file with 500k lines would only contain a handful of different class definitions,
	but thousands of entries for some classes on the same level.
	Because of that, every dictionary entry that defines a class or a property is initialized as a Generic.List type.

	Note that the parser was made very strict in order to increase performance.
	Be cautious trying to import manually edited VMF files.

	.LINK
	Export-Vmf

	.LINK
	Export-Lmp

	.LINK
	Export-Stripper

	.LINK
	Export-Vdf

	.LINK
	Export-Ini

	.LINK
	Import-Lmp

	.LINK
	Import-Stripper

	.LINK
	Import-Vdf

	.LINK
	Import-Ini
	
	.LINK
	about_Hash_Tables

	.LINK
	https://developer.valvesoftware.com/wiki/VMF_(Valve_Map_Format)
	
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
	PS> $vmfFile["classes"]["entity"][1459]["properties"]
		Name                           Value
		----                           -----
		id                             {2976892}
		angles                         {-0 -90 0}
		origin                         {5913 -1680 183}
		spawnflags                     {1}
		classname                      {logic_auto}
	PS> $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"].GetType()
		IsPublic IsSerial Name                                     BaseType
		-------- -------- ----                                     --------
		True     True     List`1                                   System.Object
	PS> $vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"][0] = 0
	PS> $vmfFile["classes"]["entity"][1459]["properties"]
		Name                           Value
		----                           -----
		id                             {2976892}
		angles                         {-0 -90 0}
		origin                         {5913 -1680 183}
		spawnflags                     {0}
		classname                      {logic_auto}

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
		[string]$Path,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
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
		#endregion
		
		# Had to do this due to a nasty bug with .NET being dependent on the context of where the script was launched from
		$Path = $(Get-AbsolutePath -Path $Path)
		if ($PSBoundParameters.ContainsKey('logFile') -and
				-not [string]::IsNullOrWhiteSpace($logFile) -and
				$(Test-Path $logFile -IsValid)) {
			$LogFile = $(Get-AbsolutePath -Path $LogFile)
		# } else {
		# 	$LogFile = $false
		}
		if (-not $Silent.IsPresent) {
			Out-Log	-Value "`nVMF | Input received: $Path"	-Path $LogFile -OneLine
		}

		try {
			$fileSize	= (Get-Item $Path).Length
			$fileSizeKB	= [math]::Round($fileSize / 1000)
			$digitsFileSize = $fileSizeKB.ToString().Length - 2

			if (-not $Silent.IsPresent) {
				$paramsLog	= @{
					Property	= "File size"
					Value		= $("{0,$digitsFileSize}Kb" -f $fileSizeKB)
					Path		= $LogFile
				}
				Out-Log @paramsLog
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
						Out-Log -Property "Estimated lines" -Value $estimatedLines -Path $LogFile
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
				Out-Log							-Value "`nVMF | Reading: Complete"	-Path $LogFile -OneLine
				Out-Log -Property "Read lines"	-Value $lineCount				-Path $LogFile
				Out-Log -Property "Elapsed time"	-Value $timeFormatted			-Path $LogFile
			}

			$vmfContent = $stringBuilder.ToString().Trim() -split "\n"
			if ($lineCount -lt 1) {
				Write-Verbose "The .vmf file is empty."
				return $false
			} else {
				# MAIN EXIT ROUTE
				return ConvertFrom-Vmf -Lines $vmfContent -LogFile $LogFile -Silent:$Silent.IsPresent
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