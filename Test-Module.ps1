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
	$PassThru = $false
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
$outputFilePath = (Split-Path -Path $InputFilePath -LeafBase) + "_"
$baseName = Join-Path -Path (Split-Path -Path $InputFilePath -Parent) -ChildPath (Split-Path -Path $InputFilePath -LeafBase)
$appendix = "_"
$testNoExtension = $false
if (Split-Path -Path $InputFilePath -Extension) {
	if ($Extension -ne ".vdf" -and $Extension -ne ".ini") {
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
		$outputFilePath = "{0}{1}{2}{3}" -f $baseName, $appendix, $count, $extension
		$count++
	} while ((Test-Path -Path $outputFilePath) -and $count -le 100)
	# If there is too muny output files, call it off
	if ($count -eq 100) {
		Write-Debug "Too many output files, go and delete some, Little Coder"
		return -1
	}
}
#endregion


$sw = [Stopwatch]::StartNew()
# Try to parse .ini file
Try {
	foreach ($module in $modulesToImport.GetEnumerator()) {
		# TODO: Get PSModuleInfo from imported modules
		Import-Module $module.Value
	}

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
					Export-Ini -Settings $iniParsed["settings"] -DebugOutput $outputFilePath -Debug
				} else {
					Export-Ini -Settings $iniParsed["settings"] -Path $outputFilePath
				}
			} else {
				if ($debugPassed) {
					Export-Ini -Settings $iniParsed["settings"] -Comments $iniParsed["comments"] -DebugOutput $outputFilePath -Debug
				} else {
					Export-Ini -Settings $iniParsed["settings"] -Comments $iniParsed["comments"] -Path $outputFilePath
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
				Export-Vdf -InputObject $vdfParsed -DebugOutput $outputFilePath -Debug
			} else {
				Export-Vdf -InputObject $vdfParsed -Path $outputFilePath
			}
		}
	} else {

	}
} catch {
	Write-Debug "Now this shit is seriously broken, we're in the catch statement"
	Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
} finally {
	foreach ($module in $modulesToImport.GetEnumerator()) {
		Remove-Module -Name $module.Value
	}
}
$sw.Stop()
Write-Host "Elapsed time: $($sw.Elapsed.Milliseconds) ms"