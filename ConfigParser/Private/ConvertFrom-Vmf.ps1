# TODO: Cleanup

using namespace System.Diagnostics

function ConvertFrom-Vmf {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
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

		if (-not $Silent.IsPresent) {
			$linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			OutLog 								-Value "`nParsing: Complete"							-Path $LogFile -OneLine
			OutLog -Property "Parsed lines"		-Value $("{0} / {1}" -f $currentLine, $Lines.Count)		-Path $LogFile
			OutLog -Property "Elapsed time"		-Value $timeFormatted									-Path $LogFile
			OutLog -Property "Speed"			-Value $("{0:n0} lines per second" -f $linesPerSecond)	-Path $LogFile
		}
	}
}