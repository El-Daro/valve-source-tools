function ConvertTo-Ini {
	<#
		.SYNOPSIS
		Converts a hashtable into an .ini file format string.
	
		.DESCRIPTION
		Converts a hashtable into a single string, formatted specifically for .ini files.
		This script is designed to work with ordered and unordered hashtables.
	
		.PARAMETER Settings
		The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
		containing sections of the .ini format.
	
		.PARAMETER Comments
		The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
		containing sections, each being its own hashtable with single-line and in-line comments of the .ini format.
		Each comment is addressed by a virtual 'key'. See NOTES for more info.
		If this parameter is ommitted, the output won't have any comments.
	
		.INPUTS
		System.Collections.IDictionary
			Both ordered and unordered hashtables are valid inputs.
	
		.OUTPUTS
		System.String
	
		.NOTES
		If the `comments` hashtable is passed, each comments is treated as one that is paired with a virtual 'key'.
		Comments can be single-line (SL), e.g occupying the whole line, or in-line (IL), e.g. following a key-value string.
		An in-line comment has the same key as `key-value` pair it relates to. The syntax for single-line comments differs.
		If an SL comment is preceeded by a valid Key-Value pair, the key is represented with `[<section-name>.<key>]` syntax.
		If an SL comment is preceeded by a valid section definition, the syntax is `[<section-name>.<section-name>]`.
		If an SL comment is not preceeded by anything or empty lines only, the virtual key is set to `[Global.Global]`.
		If you delete a key from the `settings` table before passing it to this script, the referenced comment won't be included.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Settings,

		[Parameter(Position = 1)]
		[System.Collections.IDictionary]$Comments
	)

	#region Variables
	# Note: using an Int32 as a constructor parameter will define the starting capacity (def.: 16)
	$sbLines = [System.Text.StringBuilder]::new(256)
	$defaultSectionName = "Global"
	$includeComments = $false
	$isLastLineComment = $false
	$isFirstLine = $true
	$newline = ""					# This string represents the required amound of new line characters
	if ($Comments) {
		$includeComments = $true
	}
	#endregion

	#region PROCESS
	try {
		$sw = [System.Diagnostics.Stopwatch]::StartNew()
		foreach ($section in $Settings.Keys) {					# Start with putting a section name in the brackets
			# SECTIONS
			if ($section -match $defaultSectionName -and		# If the 'Global' section is present (explicitly or implicitly)
				$Settings[$section].Count -le 0) {				# and has NO valid key-value pairs
				# GLOBAL
				if ($includeComments -and $Comments.Contains($section)) {
					# If there are single-line Comments in an otherwise empty 'Global' section
					if ($Comments[$section].Contains("[$section.$section]")) {
						[void]$sbLines.AppendFormat('{0}{1}', $newline, $Comments[$section]["[$section.$section]"])
						$isFirstLine = $false
						$isLastLineComment = $true
					}
				}
				# Since a different formatting for the first-line comments was used, the regular comments part must be skipped
				continue
			} else {
				# If it's any other section, or if the 'Global' section is empty
				$params = @{
					Section				= $section
					IsFirstLine			= [ref]$isFirstLine
					IsLastLineComment	= [ref]$isLastLineComment	
				} 
				[void]$sbLines.Append((FormatIniSectionName @params))
			}
			# SECTION COMMENTS
			if ($includeComments -and $Comments.Contains($section)) {	# If the section is in the Comments dictionary
				if ($Comments[$section].Contains("[$section]")) {		# and if said section has an in-line comment
					# Add it to the output
					[void]$sbLines.AppendFormat('    {0}', $Comments[$section]["[$section]"])
					$isFirstLine = $False
				}
				# Now check for any single-line Comments	 
				if ($Comments[$section].Contains("[$section.$section]")) {
					[void]$sbLines.AppendFormat('{0}{1}', "`n", $Comments[$section]["[$section.$section]"])
					$isFirstLine = $false
					$isLastLineComment = $true
				}
			}
			# KEY-VALUE
			if ($Settings[$section].Count -gt 0) {				# If the section has valid key-value pairs
				$params = @{
					StringBuilder		= [ref]$sbLines
					Section				= $section
					Settings			= $Settings
					Comments			= $Comments
					IncludeComments		= [ref]$includeComments
					IsFirstLine			= [ref]$isFirstLine
					IsLastLineComment	= [ref]$isLastLineComment
				}
				AppendIniKeyValuePairs @params					
			}
		}
		
		$sw.Stop()
		Write-Host "Elapsed time: $($sw.Elapsed)"

		return $sbLines.ToString()

	} catch {
		Write-Error "How did you manage to end up in this route? Here's your error, Little Coder:"
		Throw "$($MyInvocation.MyCommand): $($PSItem)"
	}
	#endregion
}