function AppendVdfBlock {
<#
	.SYNOPSIS
	Converts a single block of a hashtable to a VDF-formatted string

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .vdf files.
	This function is designed to work with ordered and unordered hashtables.

	.PARAMETER StringBuilder
	StringBuilder object contains the whole .vdf formatted string that needs to be modified. (ref)

	.PARAMETER Block
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing key-value pairs or other blocks of the .vdf format.

	.PARAMETER Depth
	Indicates the current depth inside a VDF-formatted object (a hashtable). (ref)
#>

	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[ref]$StringBuilder,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Block,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$Depth = [ref]0
	)

	$lengthMax	= EvaluateMaxVdfLineLength -Block $Block
	$tabsKey	= "".PadRight($Depth.Value, "`t")

	foreach ($key in $Block.Keys) {
		# KEY-VALUE
		# if ($Block[$key].Count -gt 0) {				# If the block has valid key-value pairs or other blocks
			$length = $key.Length + 2					# Length of the current Key-Value line
			# Difference between current line length and the max line length. If it's negative, assume 0
			[double]$charDiff = [math]::Max($lengthMax - $length, 0)
			$tabsCount = ([math]::Ceiling($charDiff / 4 ))
			$tabsValue = "".PadRight($tabsCount, "`t")
			
			if ($Block[$key].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary])) {
				# [void]$StringBuilder.Value.AppendFormat('{0}{1}"{2}"{3}{1}{4}', $newLine, $tabsKey, $key, "`n", "{")
				[void]$StringBuilder.Value.AppendFormat('{0}"{1}"{2}{0}{3}', $tabsKey, $key, "`n", "{`n")
				$Depth.Value++
				$params = @{
					StringBuilder	= $StringBuilder
					Block			= $Block[$key]
					Depth			= $Depth
				}
				AppendVdfBlock @params
			} else {
				# [void]$StringBuilder.Value.AppendFormat('{0}{1}"{2}"{3}"{4}"', "`n", $tabsKey, $key, $tabsValue, $Block[$key])
				[void]$StringBuilder.Value.AppendFormat('{0}"{1}"{2}"{3}"{4}', $tabsKey, $key, $tabsValue, $Block[$key], "`n")
			}
		# }
	}
	$Depth.Value--
	if ($Depth.Value -ge 0) {
		$tabsKey = "".PadRight($Depth.Value, "`t")
		# [void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', "`n", $tabs, "}")
		[void]$StringBuilder.Value.AppendFormat('{0}{1}{2}', $tabsKey, "}", "`n")
	}
}