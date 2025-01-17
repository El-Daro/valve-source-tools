# TODO: Cleanup

using namespace System.Diagnostics

function ConvertFrom-Vmf {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile
	)

	#region Preparing shared variables
	$linesFaulty	= 0
	$currentLine	= 0
	# $regex			= Get-VmfRegex
	#endregion

	try  {

		$sw = [Stopwatch]::StartNew()
		# All the logic is in this private function
		# $params = @{
		# 	Lines					= $Lines
		# 	CurrentLine				= [ref]$currentLine
		# 	LinesFaulty				= [ref]$linesFaulty
		# 	Depth					= [ref]0
		# 	Stopwatch				= [ref]$sw
		# 	EstimatedMilliseconds	= [ref]0
		# 	ProgressStep			= $Lines.Count / 400
		# }
		# return ParseVmfBlockRecursive @params
		$paramsIter			= @{
			Lines			= $Lines
			CurrentLine		= [ref]$currentLine
			LinesFaulty		= [ref]$linesFaulty
			Stopwatch		= [ref]$sw
		}
		return ParseVmfBlockIter @paramsIter
	} catch [FormatException] {
		Write-Error -Message "$($_.Exception.Message)"
		Write-HostError -ForegroundColor DarkYellow -NoNewline "`tCheck the file "
		Write-HostError -ForegroundColor Cyan -NoNewline "`"$(Get-AbsolutePath -Path $Path)`" "
		Write-HostError -ForegroundColor DarkYellow "for any missing curly brackets or bracket keys."
		Throw $_.Exception
	} catch {
		Write-Error "$($MyInvocation.MyCommand): Error processing the input file."
		if (				 $null	-ne $currentLine -and
			$ErrorActionPreference	-ne "Ignore"	-and
			$ErrorActionPreference	-ne "SilentlyContinue") {
			ReportLine -Path (Resolve-Path $Path) -CurrentLine $Lines[$currentLine] -LinesCount $currentLine
		}
		Throw $_.Exception
	} finally {
		$sw.Stop()
		# $parseSpeed = $sw.ElapsedMilliseconds / $currentLine * 1000
		$linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
		Write-Host -ForegroundColor DarkYellow			"Parsing: complete"
		Write-Host -ForegroundColor Magenta -NoNewLine	"   Parsed lines: "
		Write-Host -ForegroundColor Cyan				$("{0} / {1}" -f
			$currentLine, $Lines.Count)
		Write-Host -ForegroundColor Magenta -NoNewLine	"   Elapsed time: "
		Write-Host -ForegroundColor Cyan				$("{0}m {1}s {2}ms" -f
			$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds)
		Write-Host -ForegroundColor Magenta -NoNewline	"          Speed: "
		Write-Host -ForegroundColor Cyan				$("{0:n0} lines per second" -f $linesPerSecond)

		if ($LogFile) {
			$logMessage  = "`nParsing: Complete `n"
			$logMessage += "   Parsed lines: {0} / {1} `n" -f $currentLine, $Lines.Count
			$logMessage += "   Elapsed time: {0}m {1}s {2}ms `n" -f
			$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			$logMessage += "          Speed: {0:n0} lines per second" -f $linesPerSecond
			OutLog -Path $LogFile -Value $logMessage
		}
		# Write-Host "Elapsed time: $($sw.Elapsed.Hours)h $($sw.Elapsed.Minutes)m $($sw.Elapsed.Seconds)s $($sw.Elapsed.Milliseconds)ms"
		# ReportLine -Path (Resolve-Path $Path) -CurrentLine $Lines[$currentLine] -LinesCount $currentLine
	}
}