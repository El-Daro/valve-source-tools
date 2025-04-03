[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$InputFolder = "..\configs\vmf-lmp-stripper\inputs",

	[Parameter(Position = 1,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$OutputFolder = "..\configs\vmf-lmp-stripper\outputs\batch",
	
	[Parameter(Position = 2,
	Mandatory = $false)]
	[string]$Extension = ".vmf",

	[Parameter(Position = 3,
	Mandatory = $false)]
	[bool]$OneCopy = $true,

	[Parameter(Position = 4,
	Mandatory = $false)]
	# [bool]$Silent,
	[System.Management.Automation.SwitchParameter]$Silent,

	[Parameter(Position = 5,
	Mandatory = $false)]
	[System.Management.Automation.SwitchParameter]$Demo,

	[Parameter(Position = 5,
	Mandatory = $false)]
	$Note = "Batch test",

	[Parameter(Position = 6,
	Mandatory = $false)]
	[string]$LogFile = "../logs/stats_merger_batch.log"
)

$vmfsToImport		= $PSScriptRoot + "\" + $InputFolder + "\" + "*.vmf"
$lmpsToImport		= $PSScriptRoot + "\" + $InputFolder + "\" + "*.lmp"
$strippersToImport	= $PSScriptRoot + "\" + $InputFolder + "\" + "*.cfg"
$OutputFolder		+= "\" + $(Get-Date -Format "yyMMdd_HHmmss")
$outputFiles		= @( )
$Vmfs		= @( Get-ChildItem -Path $vmfsToImport		-Filter "*.vmf" -ErrorAction SilentlyContinue  | Sort-Object -Property BaseName )
$Lmps		= @( Get-ChildItem -Path $lmpsToImport		-Filter "*.lmp" -ErrorAction SilentlyContinue  | Sort-Object -Property BaseName )
$Strippers	= @( Get-ChildItem -Path $strippersToImport	-Filter "*.cfg" -ErrorAction SilentlyContinue  | Sort-Object -Property BaseName )

Write-Debug "Imported files:"
foreach ($vmf in $Vmfs) {
	Write-Debug "$vmf"
}
foreach ($lmp in $Lmps) {
	Write-Debug "$lmp"
}
foreach ($stripper in $Strippers) {
	Write-Debug "$stripper"
}
if (-not (Test-Path -Path $OutputFolder)) {
	New-Item -Path $OutputFolder -ItemType Directory | Out-Null
	Write-Debug "Output folder has been created: $OutputFolder"
} else {
	Write-Debug "Output folder already exists: $OutputFolder"
}

foreach ($vmf in $Vmfs) {
	try {
		$inputVmfFilePath	= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($vmf)
		$vmfBaseName		= Split-Path -Path $inputVmfFilePath -LeafBase
		$mapBaseName		= $vmfBaseName.Substring(0, $vmfBaseName.Length - 2)

		# Find lmp
		$lmpFound			= $false
		$inputLmpFilePath	= ""
		foreach ($lmp in $Lmps) {
			$inputLmpFilePath	= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($lmp)
			$lmpBaseName		= Split-Path -Path $inputLmpFilePath -LeafBase
			if ($mapBaseName -eq $lmpBaseName.Substring(0, $lmpBaseName.Length - 4)) {
				$lmpFound	= $true
				break
			}
		}
		if (-not $lmpFound) {
			Write-Host -ForegroundColor DarkYellow "LMP not found"
			Write-Host -ForegroundColor DarkYellow $("VMF path: {0}" -f $inputVmfFilePath)
			Write-Host -ForegroundColor DarkYellow $("Map base name: {0}" -f $mapBaseName)
			# Throw
		}

		# Find stripper
		$stripperFound			= $false
		$inputStripperFilePath	= ""
		foreach ($stripper in $Strippers) {
			$inputStripperFilePath	= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($stripper)
			$stripperBaseName		= Split-Path -Path $inputStripperFilePath -LeafBase
			if ($mapBaseName -eq $stripperBaseName) {
				$stripperFound		= $true
				break
			}
		}
		if (-not $stripperFound) {
			Write-Host -ForegroundColor DarkYellow "Stripper not found"
			Write-Host -ForegroundColor DarkYellow $("VMF path: {0}" -f $inputVmfFilePath)
			Write-Host -ForegroundColor DarkYellow $("Map base name: {0}" -f $mapBaseName)
			# continue
		}

		$outputFilePath = (Split-Path -Path $inputVmfFilePath -LeafBase) + "_"
		$baseOutputName = Join-Path -Path $outputFolder -ChildPath (Split-Path -Path $inputVmfFilePath -LeafBase)
		$Extension = Split-Path -Path $inputVmfFilePath -Extension
		
		$appendix = "_merged"
		if (-not $lmpFound -and -not $stripperFound) {
			continue		# Nothing to merge
		} elseif (-not $lmpFound) {
			$appendix = "_merged-stripper"
		} elseif (-not $stripperFound) {
			$appendix = "_merged-lmp"
		} else {
			$appendix = "_merged-lmp-stripper"
		}
		if ($OneCopy) {
			$outputFilePath = "{0}{1}{2}" -f $baseOutputName, $appendix, $Extension
		} else {
			# $appendix = "_"
			$count = 1
			do {
				$outputFilePath = "{0}{1}{2}{3}" -f $baseOutputName, $appendix, $count, $Extension
				$count++
			} while ((Test-Path -Path $outputFilePath) -and $count -le 100)
			# If there is too muny output files, call it off
			if ($count -eq 100) {
				Write-Debug "Too many output files, go and delete some, Little Coder"
				return -1
			}
		}
		$outputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputFilePath)
		$outputFiles += $outputFilePath
		$DemoTest = $true

		if ([string]::IsNullOrEmpty($inputLmpFilePath)) {
			if ([string]::IsNullOrEmpty($inputStripperFilePath)) {
				continue
			} else {
				$params = @{
					VmfPath			= $inputVmfFilePath
					StripperPath	= $inputStripperFilePath
					OutputFilePath	= $outputFilePath
					OutputExtension	= $Extension
					Note			= $Note
					LogFile			= $LogFile
					Silent			= $Silent.IsPresent
					Demo			= $Demo.IsPresent
				}
			}
		} elseif ([string]::IsNullOrEmpty($inputStripperFilePath)) {
			$params = @{
				VmfPath			= $inputVmfFilePath
				LmpPath			= $inputLmpFilePath
				OutputFilePath	= $outputFilePath
				OutputExtension	= $Extension
				Note			= $Note
				LogFile			= $LogFile
				Silent			= $Silent.IsPresent
				Demo			= $Demo.IsPresent
			}
		} else {
			$params = @{
				VmfPath			= $inputVmfFilePath
				LmpPath			= $inputLmpFilePath
				StripperPath	= $inputStripperFilePath
				OutputFilePath	= $outputFilePath
				OutputExtension	= $Extension
				Note			= $Note
				LogFile			= $LogFile
				Silent			= $Silent.IsPresent
				Demo			= $DemoTest
			}
		}
		
		$success = .\Test-MapMerger @params -Fast

		if ($success) {
			Write-Host -ForegroundColor Green "$mapBaseName merged successfully" 
			Write-Host -ForegroundColor Green "  Output: $outputFilePath" 
		}
	} catch {
		Write-Host -ForegroundColor Red "$mapBaseName failed to merge"
	}
}