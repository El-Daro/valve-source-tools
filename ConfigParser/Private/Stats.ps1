function WriteStats {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		$InputObject,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$Path,

		[System.Management.Automation.SwitchParameter]$Force = $False,

		[System.Management.Automation.SwitchParameter]$PassThru = $False
	)

	BEGIN {
		#region PREPARATION
		# Since this module is written directly in PowerShell,
		# the Common Parameters do not propagate, if this funciton is called from another module.
		# The code described in "PREPARATIONS" section is meant to fix this behaviour.
		# It is not necessary for any functions called from inside this module.
		# For more on this matter, see issue #4568 on GitHub: https://github.com/PowerShell/PowerShell/issues/4568 
		$prefVars = @{
			'ErrorActionPreference' = 'ErrorAction'
			'DebugPreference' = 'Debug'
			'VerbosePreference' = 'Verbose'
		}

		foreach ($entry in $prefVars.GetEnumerator()) {
			if (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) {
				$callersVar = $PSCmdlet.SessionState.PSVariable.Get($entry.Key)
				if ($null -ne $callersVar) {
					if ($entry.Key -eq 'DebugPreference' -and
						($callersVar.Value -eq 'Continue' -or $callersVar.Value -eq 'Inquire')
						) {
						# This is necessary for Windows PowerShell (up to 5.1.3)
						# When the common parameter '-Debug' is used, Windows PowerShell sets the $DebugPreference to 'Inquire'
						# Which asks for input every time it encounters a Write-Debug cmdlet. We don't want that
						$DebugPreference = 'Continue'
						# Write-Debug "Preference variable $($entry.Key) was set to Continue"
					} else {
						Set-Variable -Name $callersVar.Name -Value $callersVar.Value -Force -Confirm:$false -WhatIf:$false
						# Write-Debug "Preference variable $($entry.Key) was set to $($callersVar.Value)"
					}
				}
			} elseif ($PSBoundParameters.ContainsKey('Debug')) {
				$DebugPreference = 'Continue'
			}
		}
		#endregion
	}

	PROCESS {
		#region INPUT EVALUATION
		# if ($InputObject -and
		# 	$InputObject.GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]) ) {
		# 	Write-Debug "Input: $($InputObject.GetType().FullName)"
		# }
		#endregion

		# $vmf = ConvertTo-Vmf -Vmf $InputObject

		# $params = @{
		# 	Content		= $vmf
		# 	Path		= $Path
		# 	Force 		= $Force
		# 	PassThru	= $PassThru
		# 	Extension	= ".txt"
		# }
		# Out-Config @params
	}

	END { }
}