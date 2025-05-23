function ConvertTo-Stripper {
<#
	.SYNOPSIS
	Converts a hashtable into a stripper .cfg file format string.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for stripper .cfg files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER Block
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing blocks of the stripper .cfg format.
	Data is stored in the 'properties' hashtables, while modes and sub-modes are stored in the 'modes' hashtables.
	
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
		[System.Collections.IDictionary]$Stripper,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	#region PROCESS
	try {

		$estimatedOutput	= EstimateOutputStripper -Stripper $Stripper -LogFile $LogFile -Silent:$Silent.IsPresent

		#region Variables
		# Note: using an Int32 as a constructor parameter will define the starting capacity (def.: 16)
		$stringBuilder = [System.Text.StringBuilder]::new(256)
		$linesOut	= [ordered]@{
			filter	= 0;
			add		= 0;
			modify	= 0;
			lines	= 0
		}
		$sw = [System.Diagnostics.Stopwatch]::StartNew()
		#endregion
		
		$params = @{
			StringBuilder			= [ref]$stringBuilder
			StripperSection			= $Stripper
			LinesOut				= $linesOut
			Depth					= [ref]0
			StopWatch				= [ref]$sw
			EstimatedOutput			= $estimatedOutput
			ProgressStep			= $($estimatedOutput["lines"] / 50)
		}
		AppendStripperBlock @params
		
		$sw.Stop()
		
		if (-not $Silent.IsPresent) {
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			Out-Log 							-Value "`nStripper | Building output: Complete"	-Path $LogFile -OneLine
			Out-Log -Property "Elapsed time"	-Value $timeFormatted							-Path $LogFile
		}

		return $stringBuilder.ToString().Trim()

	} catch {
		Write-Error "How did you manage to end up in this route? Here's your error, Little Coder:"
		Throw "$($MyInvocation.MyCommand): $($PSItem)"
	}
	#endregion
}