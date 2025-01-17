# TODO: Expand

function OutLog {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[string]$Value,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$Path,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$Extension = ".log",

		

		[System.Management.Automation.SwitchParameter]$Force,

		[System.Management.Automation.SwitchParameter]$PassThru,
		
		[System.Management.Automation.SwitchParameter]$NoNewLine,

		$FailSafePath = "./logs/stats.log"
	)



	$params = @{
		Value		= $Value
		Path		= $Path
		Force		= $Force
		PassThru	= $PassThru
		NoNewLine	= $NoNewLine
	}
	Write-Log @params
}