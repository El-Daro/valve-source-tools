function ConvertTo-Vdf {
<#
	.SYNOPSIS
	Converts a hashtable into a .vdf file format string.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vdf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER Block
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing blocks of the .vdf format.
	
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
		[System.Collections.IDictionary]$Vdf
	)

	#region Variables
	# Note: using an Int32 as a constructor parameter will define the starting capacity (def.: 16)
	$sbLines = [System.Text.StringBuilder]::new(256)
	$Depth = 0
	#endregion

	#region PROCESS
	try {
		$sw = [System.Diagnostics.Stopwatch]::StartNew()

		# The convertion logic is supposed to be here.
		$params = @{
			StringBuilder	= [ref]$sbLines
			Block			= $Vdf
			Depth			= [ref]$Depth
		}
		AppendVdfBlock @params
		
		$sw.Stop()
		Write-Host "Elapsed time: $($sw.Elapsed)"

		return $sbLines.ToString()

	} catch {
		Write-Error "How did you manage to end up in this route? Here's your error, Little Coder:"
		Throw "$($MyInvocation.MyCommand): $($PSItem)"
	}
	#endregion
}