# Returns the header info from a byte array of .lmp file 
function Get-LmpHeader {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		$Binary,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	try {

		if ($Binary.Length -lt 20) {
			Write-Debug "Failed to read the LUMP header. The binary file is less than 20 bytes long"
			return $False
		}

		# Unused fields created to be scalable later
		$headerDescriptors	= [ordered]@{
			Offset			= @{ Offset = 0;	Length = 4;	Type = "Int32" }
			Id				= @{ Offset = 4;	Length = 4;	Type = "Int32" }
			Version			= @{ Offset = 8;	Length = 4;	Type = "Int32" }
			Length			= @{ Offset = 12;	Length = 4;	Type = "Int32" }
			Revision		= @{ Offset = 16;	Length = 4;	Type = "Int32" }
		}
		$header				= [ordered]@{ }
		
		foreach ($headerEntry in $headerDescriptors.Keys) {
			# ToInt32() will automatically read only 4 bytes starting from the offset
			$header[$headerEntry] = [BitConverter]::ToInt32($Binary, $headerDescriptors[$headerEntry]["Offset"])
		}

		return $header

	} catch {
		Write-Debug "LUMP header is corrupted"
		Write-Error -Message "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
		return $False
	} finally {

	}
}