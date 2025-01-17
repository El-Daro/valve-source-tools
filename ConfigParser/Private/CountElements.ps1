#	This is where to entry new loop ---------\/-------
#  Example: $Dictionary["classes"]["entity"]["0"]["classes"]...
#	This is the number we need      ---------\/-------
# Classes = $Dictionary["classes"]["entity"].Count
#	Properties are the same
function CountElements {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Dictionary,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[ref]$Properties,

		[Parameter(Position = 2,
		Mandatory = $true)]
		[ref]$Classes
	)

	foreach($propertyName in $Dictionary["properties"].Keys) {
		# Counting properties
		$Properties.Value += $Dictionary["properties"][$propertyName].Count
	}
		
	foreach($className in $Dictionary["classes"].Keys) {
		# Counting classes
		$Classes.Value += $Dictionary["classes"][$className].Count
		foreach ($classEntry in $Dictionary["classes"][$className]) {
			$params = @{
				Dictionary	= $classEntry
				Properties	= $Properties
				Classes		= $Classes
			}
			CountElements @params
		}
	}
}