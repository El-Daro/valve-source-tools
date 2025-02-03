# A simple test script for the .ini and .vdf parsers

using namespace System.Diagnostics

[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $true,
	ValueFromPipeline = $true)]
	[string]$InputFilePath = ".\tests\stresstest_tofix.ini",

	[Parameter(Position = 1)]
	$IgnoreCommentsPattern,

	[Parameter(Position = 2)]
	$NoComments = $false,

	[Parameter(Position = 3)]
	$Extension,

	[Parameter(Position = 4)]
	$PassThru = $false,

	[Parameter(Position = 5,
	Mandatory = $false)]
	[System.Management.Automation.SwitchParameter]$Fast,

	[Parameter(Position = 6,
	Mandatory = $false)]
	[System.Management.Automation.SwitchParameter]$Force,

	[Parameter(Position = 7,
	Mandatory = $false)]
	[System.Management.Automation.SwitchParameter]$Silent,

	[Parameter(Position = 8,
	Mandatory = $false)]
	[System.Management.Automation.SwitchParameter]$AsText,

	[Parameter(Position = 9,
	Mandatory = $false)]
	[string]$OutputFilePath,

	[Parameter(Position = 10)]
	$Note,

	[Parameter(Position = 11,
	Mandatory = $false)]
	[string]$LogFile = "../logs/stats.log"

)
# This is necessary for Windows PowerShell (up to 5.1.3)
# When the common parameter '-Debug' is used, Windows PowerShell sets the $DebugPreference to 'Inquire'
# Which asks for input every time it encounters a Write-Debug cmdlet
if ($PSBoundParameters.ContainsKey('Debug')) {
	$DebugPreference = 'Continue'
	if (-Not $IgnoreCommentsPattern) {
		$IgnoreCommentsPattern = "^#;.*;#`$"
	}
}

#region VARIABLES
$env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + "c:\Projects\PowerShell\L4D2Launcher"
$modulesToImport = @{
	# IniParser = "IniParser"
	# VdfParser = "VdfParser"
	ConfigParser = "ConfigParser"
}

$appendix = "_"
if ([string]::IsNullOrWhiteSpace($OutputFilePath) -or -not $(Test-Path $OutputFilePath -IsValid)) {
	$outputFilePath = (Split-Path -Path $InputFilePath -LeafBase) + "_"
	$baseName = Join-Path -Path (Split-Path -Path $InputFilePath -Parent) -ChildPath (Split-Path -Path $InputFilePath -LeafBase)
	$testNoExtension = $false
	if (Split-Path -Path $InputFilePath -Extension) {
		if ($Extension -ne ".vdf" -and $Extension -ne ".ini" -and $Extension -ne ".vmf") {
			$Extension = Split-Path -Path $InputFilePath -Extension
		}
	} else {
		#$Extension = ".ini"
		$testNoExtension = $true
	}
	$count = 1
	#endregion

	#region PREPARATION
	# Compose the output file name
	if ($testNoExtension) {
		do {
				$outputFilePath = "{0}{1}{2}" -f $baseName, $appendix, $count
				$count++
			} while ((Test-Path -Path ($outputFilePath + $Extension)) -and $count -le 100)
			# If there is too muny output files, call it off
			if ($count -eq 100) {
				Write-Debug "Too many output files, go and delete some, Little Coder"
				return -1
			}
	} else {
		do {
			$outputFilePath = "{0}{1}{2}{3}" -f $baseName, $appendix, $count, $Extension
			$count++
		} while ((Test-Path -Path $outputFilePath) -and $count -le 100)
		# If there is too muny output files, call it off
		if ($count -eq 100) {
			Write-Debug "Too many output files, go and delete some, Little Coder"
			return -1
		}
	}
}

# Compose log file name
if (-not $Note) {
	$additionalLog = "No note provided"
} else {
	$additionalLog = $Note
}

# $logFilePath = (Split-Path -Path $LogFile -LeafBase) + "_"
$baseLogName = Join-Path -Path (Split-Path -Path $LogFile -Parent) -ChildPath (Split-Path -Path $LogFile -LeafBase)
$logFile = "{0}{1}{2}{3}" -f
	$baseLogName,
	$appendix,
	$Extension.SubString(1, $Extension.Length - 1),
	$(Split-Path -Path $logFile -Extension)

# $logFile = "../logs/stats_" + $Extension.SubString(1, $Extension.Length - 1) + ".log"
Write-Debug "Input file: $InputFilePath"
Write-Debug "Output file: $outputFilePath"
Write-Debug "Log file: $logFile"
if (-not $Silent.IsPresent) {
	Write-Host -ForegroundColor Magenta -NoNewline	$("{0,20}: " -f "NOTE")
	Write-Host -ForegroundColor Cyan				$("{0}" -f $additionalLog)
}
#endregion

# $sw = [Stopwatch]::StartNew()
# Try to parse .ini file
Try {
	$VerbosePreferenceOld = $VerbosePreference
	$VerbosePreference = 'SilentlyContinue'
	foreach ($module in $modulesToImport.GetEnumerator()) {
		# TODO: Get PSModuleInfo from imported modules
		Import-Module $module.Value
	}
	$VerbosePreference = $VerbosePreferenceOld

	#region Logging
	# $timestamp	 = Get-Date -Format "yyyy.MM.dd HH:mm:ss"
	$success	 = $True
	if (-not $Silent.IsPresent) {
		$timestamp	 = Get-Date -UFormat "%c"

		$logMessage  = "=" * 40 + "`n"
		$logMessage += "$timestamp `n"
		$logMessage += "-" * 14 + "Test started" + "-" * 14 + "`n"
		OutLog -Value $logMessage -Path $logFile -NoConsole

		OutLog -Property "NOTE"				-Value $additionalLog	-Path $logFile -NoConsole
		OutLog -Property "Input file path"	-Value $InputFilePath	-Path $logFile -NoConsole
		OutLog -Property "Output file path"	-Value $outputFilePath	-Path $logFile -NoConsole
		OutLog -Property "Debug"			-Value $PSBoundParameters.ContainsKey('Debug').ToString()	-Path $logFile -NoConsole
		OutLog -Property "Verbose"			-Value $PSBoundParameters.ContainsKey('Verbose').ToString()	-Path $logFile -NoConsole
	}
	#endregion

	# Add properties to it
	# $err = New-Object System.Management.Automation.ErrorRecord "Line 1 `n Line 2", $null, 'NotSpecified', $null
	# $PSCmdlet.WriteError(($err))	

	if ($Extension -eq ".ini") {
		$iniParsed = Import-Ini -Path $InputFilePath -IgnoreCommentsPattern $IgnoreCommentsPattern

		if ($iniParsed) {
			# Write-Host "YAY! WE DID IT!"
			# Write-Host $iniParsed

			if  ($NoComments) {
				if ($debugPassed) {
					Export-Ini -Settings $iniParsed["settings"] -DebugOutput $outputFilePath -Force:$Force.IsPresent -Debug
				} else {
					Export-Ini -Settings $iniParsed["settings"] -Path $outputFilePath -Force:$Force.IsPresent
				}
			} else {
				if ($debugPassed) {
					Export-Ini -Settings $iniParsed["settings"] -Comments $iniParsed["comments"] -DebugOutput $outputFilePath -Force:$Force.IsPresent -Debug
				} else {
					Export-Ini -Settings $iniParsed["settings"] -Comments $iniParsed["comments"] -Path $outputFilePath -Force:$Force.IsPresent
				}
			}
		} else {
			Write-Debug "You're fucked, it's not even parsed. Go and fix it, Little Coder"
		}
	} elseif ($Extension -eq ".vdf") {
		$vdfParsed = Import-Vdf -Path $InputFilePath
		if ($vdfParsed) {
			# Write-Host "YAY! WE DID IT!"
			# Write-Host $vdfParsed

			if ($debugPassed) {
				Export-Vdf -InputObject $vdfParsed -DebugOutput $outputFilePath -Force:$Force.IsPresent -Debug
			} else {
				Export-Vdf -InputObject $vdfParsed -Path $outputFilePath -Force:$Force.IsPresent
			}

		}
	} elseif ($Extension -eq ".vmf") {
		$vmfParsed = Import-Vmf -Path $InputFilePath -LogFile $logFile -Silent:$Silent.IsPresent
		if ($vmfParsed) {
			# Write-Host "YAY! WE DID IT!"
			# Write-Host $vmfParsed

			# $loop = $true
			# $fails = 0
			# while ($loop) {
				# try {
				# 	if ($debugPassed) {
				# 		Export-Vmf -InputObject $vmfParsed -DebugOutput $outputFilePath -Debug
				# 		$loop = $false
				# 	} else {
				# 		Export-Vmf -InputObject $vmfParsed -Path $outputFilePath -Force
				# 		$loop = $false
				# 	}
				# } catch {
				# 	$fails++
				# 	Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
				# 	$response = Read-Host "Would you like to continue? y/n`n"
				# 	if ($response -ne "y") {
				# 		$loop = $false
				# 	}
				# } finally {
				# 	if (-not $loop) {
				# 		Write-Host -ForegroundColor DarkYellow "Finished exporting the file with $fails failed attempts"
				# 	}
				# }
			# }

			if ($debugPassed) {
				Export-Vmf -InputObject $vmfParsed -DebugOutput $outputFilePath -LogFile $logFile -Fast $Fast -Silent:$Silent.IsPresent -Force:$Force.IsPresent -Debug
			} else {
				Export-Vmf -InputObject $vmfParsed -Path $outputFilePath -LogFile $logFile -Fast $Fast -Silent:$Silent.IsPresent -Force:$Force.IsPresent
			}
		}
	} elseif ($Extension -eq ".lmp") {
		$lmpParsed = Import-Lmp -Path $InputFilePath -LogFile $logFile -Silent:$Silent.IsPresent
		if ($lmpParsed) {
			# Write-Host "YAY! WE DID IT!"
			
			if ($debugPassed) {
				Export-Lmp -InputObject $lmpParsed -DebugOutput $outputFilePath -LogFile $logFile -Silent:$Silent.IsPresent -AsText:$AsText.IsPresent -Force:$Force.IsPresent -Debug
			} else {
				Export-Lmp -InputObject $lmpParsed -Path $outputFilePath -LogFile $logFile -Silent:$Silent.IsPresent -AsText:$AsText.IsPresent -Force:$Force.IsPresent
			}
		}
	} elseif ($Extension -eq ".cfg") {
		$stripperParsed = Import-Stripper -Path $InputFilePath -LogFile $logFile -Silent:$Silent.IsPresent -Fast:$Fast
		if ($stripperParsed) {
			Write-Host "YAY! WE DID IT!"
			
			if ($debugPassed) {
				Export-Stripper -InputObject $stripperParsed -DebugOutput $outputFilePath -LogFile $logFile -Silent:$Silent.IsPresent -Force:$Force.IsPresent -Debug
			} else {
				Export-Stripper -InputObject $stripperParsed -Path $outputFilePath -LogFile $logFile -Silent:$Silent.IsPresent -Force:$Force.IsPresent
			}
		}
	} else {

	}

	return $true
} catch {
	$success = $false
	Write-Debug "Now this shit is seriously broken, we're in the catch statement"
	Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	OutLog -Property "$($MyInvocation.MyCommand)" -Value "$($_.Exception.Message)" -ColumnWidth 0 -Path $logFile -NoConsole

	return $false
} finally {
	#region Logging
	# $timestamp	 = Get-Date -Format "yyyy.MM.dd HH:mm:ss"

	if (-not $Silent.IsPresent) {
		
		$timestamp	 = Get-Date -UFormat "%c" 
		OutLog -Property "Success"	-Value $success		-Path $logFile -NoConsole

		$logMessage  = "-" * 15 + "Test ended" + "-" * 15 + "`n"
		$logMessage += "$timestamp `n"
		$logMessage += "=" * 40 + "`n`n"
		OutLog -Value $logMessage -Path $logFile -NoConsole
	}
	#endregion

	$VerbosePreferenceOld = $VerbosePreference
	$VerbosePreference = 'SilentlyContinue'
	foreach ($module in $modulesToImport.GetEnumerator()) {
		Remove-Module -Name $module.Value
	}
	$VerbosePreference = $VerbosePreferenceOld
}
# $sw.Stop()
# Write-Host "Elapsed time: $($sw.Elapsed.Milliseconds) ms"