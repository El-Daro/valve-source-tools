[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$InputFolder = "..\configs\lmp\inputs",

	[Parameter(Position = 1,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$OutputFolder = "..\configs\lmp\\outputs\batch",
	
	[Parameter(Position = 2,
	Mandatory = $false)]
	[string]$Extension = ".lmp",

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
	[string]$LogFile = "../logs/stats_batch.log"
)

$lmpsToImport	= $PSScriptRoot + "\" + $InputFolder + "\" + "*.lmp"
$OutputFolder	+= "\" + $(Get-Date -Format "yyMMdd_HHmmss")
$outputFiles	= @( )
$Lmps = @( Get-ChildItem -Path $lmpsToImport -Filter "*.lmp" -ErrorAction SilentlyContinue  | Sort-Object -Property BaseName )

Write-Debug "Imported files:"
foreach ($lmp in $Lmps) {
	Write-Debug "$lmp"
}
if (-not (Test-Path -Path $OutputFolder)) {
	New-Item -Path $OutputFolder -ItemType Directory | Out-Null
	Write-Debug "Output folder has been created: $OutputFolder"
} else {
	Write-Debug "Output folder already exists: $OutputFolder"
}

foreach ($lmp in $Lmps) {
	try {
		$inputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($lmp)
		$outputFilePath = (Split-Path -Path $inputFilePath -LeafBase) + "_"
		$baseOutputName = Join-Path -Path $outputFolder -ChildPath (Split-Path -Path $inputFilePath -LeafBase)
		$Extension = Split-Path -Path $InputFilePath -Extension
		if ($OneCopy) {
			$outputFilePath = "{0}{1}" -f $baseOutputName, $Extension
		} else {
			$appendix = "_"
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

		$params = @{
			InputFilePath	= $inputFilePath
			OutputFilePath	= $outputFilePath
			Extension		= $Extension
			Note			= $Note
			LogFile			= $LogFile
			Silent			= $Silent.IsPresent
		}
		
		$success = .\Test-Module @params

		if ($success) {
			Write-Host -ForegroundColor Green "$inputFilePath parsed successfully" 
		}
	} catch {
		Write-Host -ForegroundColor Red "$inputFilePath failed to parse"
	}
}