#	This is where to entry new loop ---------\/-------
#  Example: $Dictionary["classes"]["entity"]["0"]["classes"]...
#	This is the number we need      ---------\/-------
# Classes = $Dictionary["classes"]["entity"].Count
#	Properties are the same
function CountElementsIter {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
			Mandatory = $true)]
			# [System.Collections.IDictionary]$Dictionary,
		[System.Collections.IDictionary]$Dictionary,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[ref]$Properties,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$Classes
	)

	$stackBlocks		= [System.Collections.Generic.Stack[ordered]]::new()
	$counter			= 0
	$counterList		= 0
	$countProperties	= $True
	$currentBlock		= $Dictionary
	$stackBlocks.Push([ordered]@{
		Block			= $Dictionary;
		Counter			= $counter;
		CounterList		= $counterList
		CountProperties	= $countProperties
	})
	$skip				= $false

	while ($stackBlocks.Count -gt 0) {
		if ($countProperties) {
			foreach($propertyName in $currentBlock["properties"].Keys) {
				# Counting properties
				$Properties.Value += $currentBlock["properties"][$propertyName].Count
			}
		}

:cLoop	while ($counter -lt $currentBlock["classes"].Count) {
			$skip = $False
			while ($counterList -lt $currentBlock["classes"][$counter].Count) {
				$stackBlocks.Push([ordered]@{
					Block			= $currentBlock
					Counter			= $counter
					CounterList		= $counterList
					CountProperties	= $False
				})
				$currentBlock		= $currentBlock["classes"][$counter][$counterList]
				$counter			= 0
				$counterList		= 0
				$countProperties	= $True
				break cLoop
			}
			# Counting classes
			$Classes.Value += $currentBlock["classes"][$counter].Count
			$counter++
			$counterList = 0
			$skip = $True
		}

		if ($skip) {
			$block				= $stackBlocks.Pop()
			$currentBlock		= $block["Block"]
			$counter			= $block["Counter"]
			$counterList		= $block["CounterList"] + 1
			$countProperties	= $block["CountProperties"]
		} else {
			$skip = $True
		}
	}
}