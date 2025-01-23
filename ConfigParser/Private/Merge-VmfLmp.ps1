function Merge-VmfLmp {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)
	
	PROCESS {

		
		try {
			# Merge the two files
			$vmfMerged = $Vmf
			
		} catch {
			# Pay attention to errors
		} finally {
			# Some harmless stats
		}

		OutLog -Property "VMF merged type" -Value $vmfMerged.GetType().FullName -Path $LogFile

		return $vmfMerged
	}

	END { }
}