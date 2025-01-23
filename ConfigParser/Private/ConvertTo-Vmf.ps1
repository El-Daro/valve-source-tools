# TODO: Cleanup

function ConvertTo-Vmf {
<#
	.SYNOPSIS
	Converts a hashtable into a .vmf file format string.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vmf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER Block
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing blocks of the .vmf format.
	
	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs.

	.OUTPUTS
	System.String
#>

	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[bool]$Fast = $False,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	#region PROCESS
	try {

		[int]$estimatedLines = 0
		if (-not $Fast) {
			try {
				$dictEstimatedLines = EstimateLinesCount -Vmf $Vmf -LogFile $LogFile -Silent:$Silent.IsPresent
				$estimatedLines = $dictEstimatedLines["lines"]
			} catch {
				$Fast = $true
			}
		}
		if ($Fast) {
			$roughLinesEstimate = $null
			try {
				$roughLinesEstimate = ($Vmf["classes"]["entity"].Count * 50) +
				($Vmf["classes"]["world"]["0"]["classes"]["solid"].Count * 
					$Vmf["classes"]["world"]["0"]["classes"]["solid"]["0"]["classes"]["side"].Count * 
					($Vmf["classes"]["world"]["0"]["classes"]["solid"]["0"]["classes"]["side"]["0"]["properties"].Count + 1)
				)
				$estimatedLines = $roughLinesEstimate
				# $estimationError = ($roughLinesEstimate - $estimatedLines["lines"]) / $estimatedLines["lines"]
				# Write-Host -ForegroundColor Magenta -NoNewLine	"Rough lines est: "
				# Write-Host -ForegroundColor Cyan				$("{0}" -f
				# 	$roughLinesEstimate)
				# Write-Host -ForegroundColor Cyan				$("{0} ({1:n2}% off)" -f
				# 	$roughLinesEstimate, $($estimationError * 100))

				# if ($LogFile) {
					# $logMessage  = "Rough lines est: {0} `n" -f $roughLinesEstimate
					# $logMessage  = "Rough lines est: {0} ({1:n2}% off) `n" -f $roughLinesEstimate, $($estimationError * 100)
					# OutLog -Path $LogFile -Value $logMessage

				if (-not $Silent.IsPresent) {
					OutLog -Property "Rough lines estimate" -Value $roughLinesEstimate -Path $LogFile
				}
				# }
			} catch {
				continue				# Fuhged about it
				# throw $_.Exception
			}
		}

		#region Variables
		# Note: using an Int32 as a constructor parameter will define the starting capacity (def.: 16)
		$stringBuilder = [System.Text.StringBuilder]::new(256)
		$sw = [System.Diagnostics.Stopwatch]::StartNew()
		#endregion

		# The convertion logic is supposed to be here.
		$params = @{
			StringBuilder			= [ref]$stringBuilder
			VmfSection				= $Vmf
			Depth					= [ref]0
			StopWatch				= [ref]$sw
			EstimatedLines			= [ref]$estimatedLines
			ProgressStep			= $($estimatedLines / 50)
		}
		AppendVmfBlockRecursive @params
		# $paramsIter = @{
		# 	StringBuilder			= [ref]$stringBuilder
		# 	VmfSection				= $Vmf
		# 	Stopwatch				= [ref]$sw
		# 	EstimatedLines			= $estimatedLines
		# }
		# AppendVmfBlockIter @paramsIter
		
		$sw.Stop()
		
		if (-not $Silent.IsPresent) {
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			OutLog 							-Value "`nBuilding output: Complete"	-Path $LogFile -OneLine
			OutLog -Property "Elapsed time"	-Value $timeFormatted					-Path $LogFile
		}

		return $stringBuilder.ToString().Trim()

	} catch {
		Write-Error "How did you manage to end up in this route? Here's your error, Little Coder:"
		Throw "$($MyInvocation.MyCommand): $($PSItem)"
	}
	#endregion
}