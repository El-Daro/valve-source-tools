using namespace System.Diagnostics

function Import-Lmp {
<#
	.SYNOPSIS
	Reads a .lmp file and creates a corresponding hashtable.

	.DESCRIPTION
	Reads through a .lmp file and populates an ordered hashtable that consists of the header and data hashtables.

	.PARAMETER Path
	Specifies the path to the .lmp file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Silent
	If specified, suppresses console output

	.INPUTS
	System.String
		You can pipe a string containing a path to this function.

	.OUTPUTS
	System.Collections.Specialized.OrderedDictionary

	.NOTES
	Empty lines and possible comments are ignored (need to verify if LUMP files may contain comments at all).
	A key cannot be empty or contain symbols `"` and `//`.
	Both key and value should be enclosed in double quotes (`" "`) and separated by one whitespace.
	Every section (class) is defined in curly brackets.
	LMP files have a one-level structure; each class may only contain properties, but not other classes.
	
	Note that key-value pairs are not always unique:
	it is possible to define the same key multiple times with different values
	(i)n practice only seen in the implied 'connections' class that defines outcoming script actions).
	Connections are not defined as their own class, but rather as properties of a parent class.
	Because of that, every dictionary entry that defines a class or a property is initialized as a Generic.List type.

	Note that the parser was made very strict in order to increase performance.
	Be cautious trying to import manually edited LMP files.
	And although this cmdlet will ignore wrong headers, the game won't.

	.LINK
	Export-Lmp

	.LINK
	Export-Vmf

	.LINK
	Export-Vdf

	.LINK
	Export-Ini

	.LINK
	Import-Vmf

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
	PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
	PS> $lmpFile

		Name                           Value
		----                           -----
		header                         {[Offset, 20], [Id, 0], [Version, 0], [Length, 600261]…}
		data                           {[hammerid-1, System.Collections.Specialized.OrderedDictionary], [hammerid-162364, System.Collections.…
	
	# Note that not all entries may start with "hammerid-": some would start with "classname-"
	PS> $lmpFile["data"].Keys

		hammerid-1
		hammerid-162364
		hammerid-163642
		hammerid-1030150
		hammerid-1030152
		...

	PS> $lmpFile["data"][0]

		Name                           Value
		----                           -----
		world_mins                     {1023 -10496 -224}
		timeofday                      {2}
		startmusictype                 {1}
		skyname                        {sky_l4d_c5_1_hdr}
		musicpostfix                   {BigEasy}
		maxpropscreenwidth             {-1}
		detailvbsp                     {detail.vbsp}
		detailmaterial                 {detail/detailsprites_overgrown}
		classname                      {worldspawn}
		mapversion                     {5359}
		hammerid                       {1}

	PS> $lmpFile["data"].Count	
	1616
		
	.EXAMPLE
	PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
	PS> $lmpFile["data"]["hammerid-2935785"]
		Name                           Value
		----                           -----
		SunSpreadAngle                 {0}
		pitch                          {-45}
		angles                         {0 150 0}
		_lightscaleHDR                 {1}
		_lightHDR                      {-1 -1 -1 1}
		_light                         {202 214 227 100}
		classname                      {light_directional}
		hammerid                       {2935785}

	PS> $lmpFile["data"]["hammerid-2935785"]["angles"].GetType()
		
		IsPublic IsSerial Name                                     BaseType
		-------- -------- ----                                     --------
		True     True     List`1                                   System.Object

	PS> $lmpFile["data"]["hammerid-2935785"]["angles"][0] = "45 120 0"
	PS> $lmpFile["data"]["hammerid-2935785"]
		Name                           Value
		----                           -----
		SunSpreadAngle                 {0}
		pitch                          {-45}
		angles                         {45 120 0}
		_lightscaleHDR                 {1}
		_lightHDR                      {-1 -1 -1 1}
		_light                         {202 214 227 100}
		classname                      {light_directional}
		hammerid                       {2935785}

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
			if (Test-Path -Path $($Path + ".lmp")) {			# See if adding '.lmp' actually helps
				$Path += ".lmp"									# If so, add the extension and proceed with the converting
				Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
			} else {
				Write-Error "$($MyInvocation.MyCommand): Could not find file '$(Get-AbsolutePath -Path $Path)'"
				Write-HostError  -ForegroundColor DarkYellow "Could not find the file. Check the spelling of the filename before using it explicitly."
				throw [System.IO.FileNotFoundException]	"Could not find file '$(Get-AbsolutePath -Path $Path)'"
			}
		} elseif ($Path -notmatch "(^(?:.+)\.lmp`"*`'*)`$") {	# If file DOES exist, see if it is not a .lmp one
			Write-Error "$($MyInvocation.MyCommand): File is not .lmp: $(Get-AbsolutePath -Path $Path)"
			Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename and its extension."
			throw [System.IO.FileFormatException] "File format is incorrect: $(Get-AbsolutePath -Path $Path)"
		}
		Write-Verbose "The input path is correct. Processing..."
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		#endregion
		
		# Had to do this due to a nasty bug with .NET being dependent on the context of where the script was launched from
		$Path = $(Get-AbsolutePath -Path $Path)
		$LogFile = $(Get-AbsolutePath -Path $LogFile)

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
			
			$sw = [Stopwatch]::StartNew()

			$lmpBinary	= [System.IO.File]::ReadAllBytes($Path)
			$lmpHeader	= Get-LmpHeader -Binary $lmpBinary -LogFile $LogFile -Silent:$Silent.IsPresent
			$offset		= 20
			if ($null -ne $lmpHeader) {
				$offset	= $lmpHeader["Offset"]
			}
			$params		= @{
				# We need to skip the header, which should always be 20 bytes
				Binary	= $lmpBinary[$offset..$($lmpBinary.Length - 1)]
				LogFile	= $LogFile 
				Silent 	= $Silent.IsPresent
			}
			$lmpContent	= Get-LmpData @params
			
			$sw.Stop()

			if (-not $Silent.IsPresent) {
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog							-Value "`nReading: Complete"	-Path $LogFile -OneLine
				# OutLog -Property "Lmp header"		-Value $($lmpHeader | ConvertTo-Json -Compress)	-Path $LogFile
				$sLmpHeader	= $lmpHeader.Keys.ForEach({"{0}={1}" -f $_, $($lmpHeader[$_])}) -join ' | '
				OutLog -Property "Lmp header"		-Value $sLmpHeader			-Path $LogFile
				OutLog -Property "Lmp data lines"	-Value $lmpContent.Length	-Path $LogFile
				OutLog -Property "Elapsed time"		-Value $timeFormatted		-Path $LogFile
			}

			if ($lmpContent.Count -lt 2) {
				Write-Verbose "The .lmp file is empty."
				return $false
			} else {
				$lmpData = ConvertFrom-Lmp -Lines $lmpContent -LogFile $LogFile -Silent:$Silent.IsPresent
			}

			# MAIN EXIT ROUTE
			return [ordered]@{ header = $lmpHeader; data = $lmpData}

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