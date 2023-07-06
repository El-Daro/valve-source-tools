function EvaluateMaxVdfLineLength {
	# This is purely for nice visuals. Calculates the max line length to correctly place in-line comments
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Block
	)

	$lengthMax = 4
	$additionalLength = 0
	foreach ($key in $Block.Keys) {
		# Determine the proper indentation for in-line comments, which is a minimum between 100 and the max line length
		$lengthMax = [math]::min( [math]::max(($key.Length + 2), $lengthMax), 100 )
	}
	if ($lengthMax % 4 -eq 0) {
		# We need at least some space before value
		$additionalLength = 4
	}
	# Adjusting the max length for the TABs identation
	return [math]::Ceiling($lengthMax / 4) * 4 + $additionalLength
}