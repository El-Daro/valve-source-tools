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
		[string]$LogFile
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
		# Write-Host "Elapsed time: $($sw.Elapsed)"
		Write-Host -ForegroundColor DarkYellow "Output estimation: Complete"
		if ($estimatedLines -gt 0) {
			Write-Host -ForegroundColor Magenta	"     Properties: $properties"
			Write-Host -ForegroundColor Magenta "        Classes: $classes"
			Write-Host -ForegroundColor Magenta "Estimated lines: $estimatedLines"
			Write-Host -ForegroundColor Magenta -NoNewLine	"   Elapsed time: "
			Write-Host -ForegroundColor Cyan				$("{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds)

			if ($LogFile) {
				$logMessage  = "`nOutput estimation: Complete `n"
				$logMessage += "     Properties: $properties `n"
				$logMessage += "        Classes: $classes `n"
				$logMessage += "Estimated lines: $estimatedLines `n"
				$logMessage += "   Elapsed time: {0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog -Path $LogFile -Value $logMessage
			}
		} else {
			Write-Host -ForegroundColor DarkYellow "Failed to estimate lines count"
		}

	}

	return [ordered]@{ properties = $properties; classes = $classes; lines = $($properties + ($classes * 3)) }
}