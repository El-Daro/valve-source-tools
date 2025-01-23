# TODO: Cleanup

function EstimateLinesCount {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	$estimatedLines = 0
	# Okay, so let's do some statistics analysis first
	try {

		$sw = [System.Diagnostics.Stopwatch]::StartNew()
		$properties	= 0
		$classes	= 0
		$params = @{
			Dictionary	= $Vmf
			Properties	= [ref]$properties
			Classes		= [ref]$classes
		}
		# CountElements @params
		CountElementsIter @params

		$estimatedLines = $properties + ($classes * 3)

	} catch {
		Write-Host -ForegroundColor DarkYellow "Catchiments"
		Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
	} finally {
		$sw.Stop()
		if (-not $Silent.IsPresent) {
			if ($estimatedLines -gt 0) {
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog								-Value "`nOutput estimation: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Properties"		-Value $properties						-Path $LogFile
				OutLog -Property "Classes"			-Value $classes							-Path $LogFile
				OutLog -Property "Estimated lines"	-Value $estimatedLines					-Path $LogFile
				OutLog -Property "Elapsed time"		-Value $timeFormatted					-Path $LogFile
			} else {
				OutLog	-Value "`nFailed to estimate lines count"	-Path $LogFile -OneLine
			}
		}

	}

	return [ordered]@{ properties = $properties; classes = $classes; lines = $($properties + ($classes * 3)) }
}