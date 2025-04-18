# A simple test script for merging .vmf, .lmp and Stripper's .cfg files into a new .vmf

using namespace System.Diagnostics

[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $true)]
	# [string]$VmfPath = ".\resources\merger\mergeTest.vmf",
	# [string]$VmfPath = ".\resources\merger\vmf-lmp-stripper\c5m3_cemetery_d.vmf",
	[string]$VmfPath,

	[Parameter(Position = 1,
	Mandatory = $false)]
	# [string]$LmpPath = ".\resources\merger\mergeTest.lmp",
	# [string]$LmpPath = ".\resources\merger\c5m3_cemetery_l_0.lmp",
	[string]$LmpPath,

	[Parameter(Position = 2,
	Mandatory = $false)]
	# [string]$StripperPath = ".\resources\merger\mergeTest.cfg",
	# [string]$StripperPath = ".\resources\merger\c5m3_cemetery.cfg",
	[string]$StripperPath,

	[Parameter(Position = 3)]
	[string]$OutputFilePath,

	[Parameter(Position = 4)]
	$OutputExtension = ".vmf",

	[Parameter(Position = 5)]
	$PassThru = $false,

	[Parameter(Position = 6)]
	[System.Management.Automation.SwitchParameter]$Fast,

	[Parameter(Position = 7)]
	[System.Management.Automation.SwitchParameter]$Force,

	[Parameter(Position = 8)]
	[System.Management.Automation.SwitchParameter]$Silent,

	[Parameter(Position = 9)]
	[System.Management.Automation.SwitchParameter]$Demo,

	[Parameter(Position = 10)]
	[System.Management.Automation.SwitchParameter]$AsText,

	[Parameter(Position = 11)]
	$Note,

	[Parameter(Position = 12,
	Mandatory = $false)]
	[string]$LogFile = ".\logs\stats_merger.log"

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

#region VARIABLES and PREPARATIONS
$oldPSModulePath = $env:PSModulePath
$env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PSScriptRoot
$modulesToImport = @{
	PSResourceParser	= "PSResourceParser"
	PSSourceEngineTools	= "PSSourceEngineTools"
}

$appendix = "_merged_"
if ([string]::IsNullOrWhiteSpace($OutputFilePath) -or -not $(Test-Path $OutputFilePath -IsValid)) {
	$outputFilePath = (Split-Path -Path $VmfPath -LeafBase) + "_"
	$baseName = Join-Path -Path (Split-Path -Path $VmfPath -Parent) -ChildPath (Split-Path -Path $VmfPath -LeafBase)
	$maxOutputFiles = 100
	$count = 1

	# Compose the output file name
	do {
		$outputFilePath = "{0}{1}{2}{3}" -f $baseName, $appendix, $count, $OutputExtension
		$count++
	} while ((Test-Path -Path $outputFilePath) -and $count -le $maxOutputFiles)
	# If there is too muny output files, call it off
	if ($count -eq $maxOutputFiles) {
		Write-Debug "Too many output files have been generated ($maxOutputFiles). Stopping execution"
		Write-Debug "Last tried output path: $outputFilePath"
		return -1
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
	$OutputExtension.SubString(1, $OutputExtension.Length - 1),
	$(Split-Path -Path $logFile -Extension)

# $logFile = "../logs/stats_" + $OutputExtension.SubString(1, $OutputExtension.Length - 1) + ".log"
Write-Debug "Input vmf file: $VmfPath"
Write-Debug "Input lmp file: $LmpPath"
Write-Debug "Input stripper file: $StripperPath"
Write-Debug "Output vmf file: $outputFilePath"
Write-Debug "Log file: $logFile"
if (-not $Silent.IsPresent) {
	Write-Host -ForegroundColor Magenta -NoNewline	$("{0,25}: " -f "NOTE")
	Write-Host -ForegroundColor Cyan				$("{0}" -f $additionalLog)
}
#endregion

try {
	$VerbosePreferenceOld = $VerbosePreference
	$VerbosePreference = 'SilentlyContinue'
	foreach ($module in $modulesToImport.GetEnumerator()) {
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

		OutLog -Property "NOTE"					-Value $additionalLog	-Path $logFile -NoConsole
		OutLog -Property "Input vmf path"		-Value $VmfPath			-Path $logFile -NoConsole
		OutLog -Property "Input lmp path"		-Value $LmpPath			-Path $logFile -NoConsole
		OutLog -Property "Input stripper path"	-Value $StripperPath	-Path $logFile -NoConsole
		OutLog -Property "Output vmf path"		-Value $outputFilePath	-Path $logFile -NoConsole
		OutLog -Property "Debug"				-Value $PSBoundParameters.ContainsKey('Debug').ToString()	-Path $logFile -NoConsole
		OutLog -Property "Verbose"				-Value $PSBoundParameters.ContainsKey('Verbose').ToString()	-Path $logFile -NoConsole
	}
	#endregion
	
	$vmfParsed			= Import-Vmf -Path $VmfPath	-LogFile $logFile -Silent:$Silent.IsPresent
	$lmpParsed			= $false
	if ($PSBoundParameters.ContainsKey('LmpPath')) {
		$lmpParsed		= Import-Lmp -Path $LmpPath	-LogFile $logFile -Silent:$Silent.IsPresent
	}
	$stripperParsed		= $false
	if ($PSBoundParameters.ContainsKey('StripperPath')) {
		$stripperParsed	= Import-Stripper -Path $StripperPath -LogFile $logFile -Silent:$Silent.IsPresent
	}

	if ($vmfParsed) {
		if ($lmpParsed) {
			if ($stripperParsed) {
				$vmfMerged = Merge-Map -Vmf $vmfParsed -Lmp $lmpParsed -Stripper $stripperParsed -LogFile $logFile -Silent:$Silent.IsPresent -Demo:$Demo.IsPresent
			} else {
				$vmfMerged = Merge-Map -Vmf $vmfParsed -Lmp $lmpParsed -LogFile $logFile -Silent:$Silent.IsPresent
			}
		} elseif ($stripperParsed) {
			$vmfMerged = Merge-Map -Vmf $vmfParsed -Stripper $stripperParsed -LogFile $logFile -Silent:$Silent.IsPresent -Demo:$Demo.IsPresent
		} else {
			$vmfMerged = $false
			$success = $false
			OutLog -Value "Neither LMP, nor Stripper config were provided" -Path $LogFile -OneLine
		}

		if ($vmfMerged) {
			if ($debugPassed) {
				Export-Vmf -InputObject $vmfMerged -DebugOutput $outputFilePath -LogFile $logFile -Fast $Fast -Silent:$Silent.IsPresent -Force:$Force.IsPresent -Debug
			} else {
				Export-Vmf -InputObject $vmfMerged -Path $outputFilePath -LogFile $logFile -Fast $Fast -Silent:$Silent.IsPresent -Force:$Force.IsPresent
			}
		}
	} else {
		$success = $false
		OutLog -Value "Failed to parse input files" -Path $LogFile -OneLine
	}
	return $success
} catch {
	$success = $false
	Write-Debug "Now this shit is seriously broken, we're in the catch statement"
	Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	OutLog -Property "$($MyInvocation.MyCommand)" -Value "$($_.Exception.Message)" -ColumnWidth 0 -Path $logFile -NoConsole

	return $success
} finally {
	#region Logging
	if (-not $Silent.IsPresent) {
		try {
			$timestamp	 = Get-Date -UFormat "%c" 
			OutLog -Property "Success"	-Value $success		-Path $logFile -NoConsole

			$logMessage  = "-" * 15 + "Test ended" + "-" * 15 + "`n"
			$logMessage += "$timestamp `n"
			$logMessage += "=" * 40 + "`n`n"
			OutLog -Value $logMessage -Path $logFile -NoConsole
			Write-Host ""
		} catch {
			# Do nothing
		}
	}
	#endregion

	$VerbosePreferenceOld = $VerbosePreference
	$VerbosePreference = 'SilentlyContinue'
	foreach ($module in $modulesToImport.GetEnumerator()) {
		Remove-Module -Name $module.Value
	}
	$VerbosePreference = $VerbosePreferenceOld
	$env:PSModulePath = $oldPSModulePath
}