[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$InputFolder = "resources\merger\vmf\inputs",

	[Parameter(Position = 1,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$OutputFolder = "resources\merger\vmf\outputs\batch",
	
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
	$Note = "Batch test",

	[Parameter(Position = 6,
	Mandatory = $false)]
	[string]$LogFile = ".\logs\stats_batch.log"
)

$vmfsToImport	= $PSScriptRoot + "\" + $InputFolder + "\" + "*.vmf"
$OutputFolder	+= "\" + $(Get-Date -Format "yyMMdd_HHmmss")
$outputFiles	= @( )
$Vmfs = @( Get-ChildItem -Path $vmfsToImport -Filter "*.vmf" -ErrorAction SilentlyContinue  | Sort-Object -Property Length )

Write-Debug "Imported files:"
foreach ($vmf in $Vmfs) {
	Write-Debug "$vmf"
}
if (-not (Test-Path -Path $OutputFolder)) {
	New-Item -Path $OutputFolder -ItemType Directory | Out-Null
	Write-Debug "Output folder has been created: $OutputFolder"
} else {
	Write-Debug "Output folder already exists: $OutputFolder"
}

foreach ($vmf in $Vmfs) {
	try {
		$inputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($vmf)
		$outputFilePath = (Split-Path -Path $inputFilePath -LeafBase) + "_"
		$baseOutputName = Join-Path -Path $outputFolder -ChildPath (Split-Path -Path $inputFilePath -LeafBase)
		$Extension = Split-Path -Path $InputFilePath -Extension
		if ($OneCopy) {
			$outputFilePath = "{0}{1}" -f $baseOutputName, $Extension
		} else {
			$appendix = "_"
			$maxOutputFiles = 100
			$count = 1
			do {
				$outputFilePath = "{0}{1}{2}{3}" -f $baseOutputName, $appendix, $count, $Extension
				$count++
			} while ((Test-Path -Path $outputFilePath) -and $count -le $maxOutputFiles)
			# If there is too muny output files, call it off
			if ($count -eq $maxOutputFiles) {
				Write-Debug "Too many output files, go and delete some, Little Coder"
				return -1
			}
		}
		$outputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputFilePath)
		$outputFiles += $outputFilePath

		$params = @{
			InputFilePath	= $inputFilePath
			OutputFilePath	= $outputFilePath
			Extension		= $Extension
			Note			= $Note
			LogFile			= $LogFile
			Silent			= $Silent.IsPresent
		}
		$success = .\Test-Module @params -Fast
		if ($success) {
			Write-Host -ForegroundColor Green "$inputFilePath parsed successfully"
			Write-Host -ForegroundColor Green "  Output: $outputFilePath"
		}
	} catch {
		Write-Host -ForegroundColor Red "$inputFilePath failed to parse"
	}
}