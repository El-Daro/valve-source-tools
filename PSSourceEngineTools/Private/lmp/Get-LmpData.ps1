# Returns an array of strings converted from a byte array

function Get-LmpData {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		$Binary,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	try  {
		return [System.Text.Encoding]::UTF8.GetString($Binary).Trim("`0").Trim().Split("`n")
	} catch {
		Write-Debug "Failed to read the LUMP data"
		Write-Error "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
		Throw $_.Exception
	}
}