function ConvertTo-Lmp {
	<#
		.SYNOPSIS
		Converts a hashtable into an .lmp byte array.
	
		.DESCRIPTION
		Converts a hashtable into a byte array formatted specifically for .lmp files.
		This function is designed to work with ordered and unordered hashtables.
	
		.PARAMETER Lmp
		The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
		containing 'header' and 'data' hashtables.
		'Data' hashtable is assumed to contain blocks of the .lmp format, each represented as hashtable.
		Every property is assumed to be a Generic.List type.

		.PARAMETER AsText
		If specified, output file is written as plain text without header
		
		.PARAMETER Silent
		If specified, suppresses console output
		
		.INPUTS
		System.Collections.IDictionary
			Both ordered and unordered hashtables are valid inputs.
	
		.OUTPUTS
		System.Array[Bytes]
	#>

		[CmdletBinding()]
		Param (
			[Parameter(Position = 0,
			Mandatory = $true)]
			[System.Collections.IDictionary]$Lmp,

			[Parameter(Position = 1,
			Mandatory = $false)]
			[string]$LogFile,

			[System.Management.Automation.SwitchParameter]$AsText,
	
			[System.Management.Automation.SwitchParameter]$Silent
		)

		#region PROCESS
		try {

			$sw = [System.Diagnostics.Stopwatch]::StartNew()

			$estimatedOuput	= EstimateOutputLmp -Lmp $Lmp -LogFile $LogFile -Silent:$Silent.IsPresent

			$params		= @{
				Lmp					= $Lmp
				LogFile				= $LogFile
				EstimatedSections	= $estimatedOuput["sections"]
				StopWatch			= [ref]$sw
				Silent				= $Silent.IsPresent
			}
			$dataString				= Set-LmpData @params
			$dataBytes				= [System.Text.Encoding]::UTF8.GetBytes($dataString)
			$dataBytes				+= 0x0A
			$dataBytes				+= 0x00
			if (-not $dataString) {
				OutLog -Value "Lmp data is corrupted" -Path $LogFile -OneLine
			}

			$params			= @{
				Lmp			= $Lmp
				Size		= $dataBytes.Count
				LogFile		= $LogFile
				Silent		= $Silent.IsPresent
			}
			$headerBytes	= [byte[]](Set-LmpHeader @params)
			if (-not $headerBytes) {
				OutLog -Value "Lmp header is corrupted" -Path $LogFile -OneLine
			}

			if ($AsText.IsPresent) {
				$output		= $dataString
			} else {
				$output		= [byte[]]($headerBytes + $dataBytes)
			}

			$sw.Stop()

			if (-not $Silent.IsPresent) {
				$timeFormatted = "{0}m {1}s {2}ms" -f
					$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
				OutLog 							-Value "`nBuilding output: Complete"	-Path $LogFile -OneLine
				OutLog -Property "Elapsed time"	-Value $timeFormatted					-Path $LogFile
			}

			# MAIN EXIT ROUTE
			return $output
	
		} catch {
			Write-Error "How did you manage to end up in this route? Here's your error, Little Coder:"
			Throw "$($MyInvocation.MyCommand): $($PSItem)"
		}
		#endregion
	}