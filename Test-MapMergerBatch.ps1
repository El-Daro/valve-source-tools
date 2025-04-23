[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$InputFolder = "resources\merger\inputs",

	[Parameter(Position = 1,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$OutputFolder = "resources\merger\outputs\batch",
	
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
	[string]$LogFile = ".\logs\stats_merger_batch.log"
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
	New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
	Write-Debug "Output folder has been created: $OutputFolder"
} else {
	Write-Debug "Output folder already exists: $OutputFolder"
}

foreach ($vmf in $Vmfs) {
	try {
		$inputVmfFilePath	= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($vmf)
		# $vmfBaseName		= Split-Path -Path $inputVmfFilePath -LeafBase
		$vmfBaseName		= [IO.Path]::GetFileNameWithoutExtension($inputVmfFilePath)
		$mapBaseName		= $vmfBaseName.Substring(0, $vmfBaseName.Length - 2)

		# Find lmp
		$lmpFound			= $false
		$inputLmpFilePath	= ""
		foreach ($lmp in $Lmps) {
			$inputLmpFilePath	= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($lmp)
			# $lmpBaseName		= Split-Path -Path $inputLmpFilePath -LeafBase
			$lmpBaseName		= [IO.Path]::GetFileNameWithoutExtension($inputLmpFilePath)
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
			# $stripperBaseName		= Split-Path -Path $inputStripperFilePath -LeafBase
			$stripperBaseName		= [IO.Path]::GetFileNameWithoutExtension($inputStripperFilePath)
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

		# $outputFilePath = (Split-Path -Path $inputVmfFilePath -LeafBase) + "_"
		$outputFilePath = ([IO.Path]::GetFileNameWithoutExtension($inputVmfFilePath)) + "_"
		$baseOutputName = Join-Path -Path $outputFolder -ChildPath ([IO.Path]::GetFileNameWithoutExtension($inputVmfFilePath)) # (Split-Path -Path $inputVmfFilePath -LeafBase)
		# $Extension = Split-Path -Path $inputVmfFilePath -Extension
		$Extension = [IO.Path]::GetExtension($inputVmfFilePath)
		
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
			$maxOutputFiles = 100
			do {
				$outputFilePath = "{0}{1}{2}{3}" -f $baseOutputName, $appendix, $count, $Extension
				$count++
			} while ((Test-Path -Path $outputFilePath) -and $count -le $maxOutputFiles)
			# If there is too muny output files, call it off
			if ($count -eq $maxOutputFiles) {
				Write-Debug "Too many output files have been generated ($maxOutputFiles). Stopping execution"
				Write-Debug "Last tried output path: $outputFilePath"
				return -1
			}
		}
		$outputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputFilePath)
		$outputFiles += $outputFilePath

		$params = @{
			VmfPath			= $inputVmfFilePath
			OutputFilePath	= $outputFilePath
			OutputExtension	= $Extension
			Note			= $Note
			LogFile			= $LogFile
			Silent			= $Silent.IsPresent
			Demo			= $Demo.IsPresent
		}

		if ([string]::IsNullOrEmpty($inputLmpFilePath) -and
			[string]::IsNullOrEmpty($inputStripperFilePath)) {
			continue
		}
		if (-not [string]::IsNullOrEmpty($inputLmpFilePath)) {
			$params.Add("LmpPath", $inputLmpFilePath)
		}
		if (-not [string]::IsNullOrEmpty($inputStripperFilePath)) {
			$params.Add("StripperPath", $inputStripperFilePath)
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