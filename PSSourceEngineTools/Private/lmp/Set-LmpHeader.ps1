# Returns .lmp header as a byte array 
function Set-LmpHeader {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		$Lmp,

		[Parameter(Position = 1,
		Mandatory = $true)]
		$Size,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	try {

		$header			= [byte[]]::new(0)
		$headerOld		= [byte[]]::new(0)
		$header			+= [BitConverter]::GetBytes([Int32]20)		# Header offset
		$header			+= [BitConverter]::GetBytes([Int32]$Lmp["header"]["Id"])
		$header			+= [BitConverter]::GetBytes([Int32]$Lmp["header"]["Version"])
		$header			+= [BitConverter]::GetBytes([Int32]$Size)
		$header			+= [BitConverter]::GetBytes([Int32]$Lmp["header"]["Revision"])
		
		foreach ($headerEntry in $Lmp["header"].Keys) {
			$strValue	= $Lmp["header"][$headerEntry]
			$headerOld	+= [BitConverter]::GetBytes([Int32]$strValue)
			# [Array]::Copy($headerBytes, 0, $header, $offset, $length)
		}

		if ($PSBoundParameters.ContainsKey('Debug')) {
			Out-Log -Property "Header (old)" -Value "$headerOld"	-Path $LogFile
			Out-Log -Property "Header (new)" -Value "$header"	-Path $LogFile
		}

		return [byte[]]$header

	} catch {
		Write-Debug "LUMP header is corrupted"
		Write-Error -Message "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
		return $False
	} finally {

	}
}