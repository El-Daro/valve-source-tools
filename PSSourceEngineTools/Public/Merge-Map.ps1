function Merge-Map {
<#
	.SYNOPSIS
	Merges .vmf, .lmp and Stripper's .cfg files

	.DESCRIPTION
	Takes .vmf file and either of- or both .lmp and Stripper's .cfg files, and merges them together in a new .vmf file.
	By default, it performs all of the Stripper's documented procedures (refer to the LINKS section for Stripper's repo).
	Use `-Demo` parameter to simulate removal of entities (see Stripper's `filter` feature) with an additional visgroups.
	New visgroups are created for every Stripper's feature: `filter` (removal), `add` (addition), `modify` (modification).
	As well as for .lmp additions.

	.PARAMETER Vmf
	The VMF object to merge. It can be ordered or unordered hashtable. Must contain 'properties' and 'classes' hashtables inside.

	.PARAMETER Lmp
	The LMP object to merge. It can be ordered or unordered hashtable. Must contain 'header' and 'data' hashtables inside.
	
	.PARAMETER Stripper
	The Stripper object to merge. It can be ordered or unordered hashtable. May contain 'filter', 'add' or 'modify' hashtables inside.

	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.

	.OUTPUTS
	System.Collections.IDictionary

	.LINK
	Import-Vmf

	.LINK
	Import-Lmp
	
	.LINK
	Import-Stripper

	.LINK
	Export-Vmf

	.LINK
	Export-Lmp

	.LINK
	Export-Stripper

	.LINK
	https://developer.valvesoftware.com/wiki/VMF_(Valve_Map_Format)

	.LINK
	https://developer.valvesoftware.com/wiki/Lump_file_format

	.LINK
	https://forums.alliedmods.net/showthread.php?t=39439

	.LINK
	https://www.bailopan.net/stripper/

	.LINK
	https://github.com/alliedmodders/stripper-source/tree/master
	
	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
	PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
	PS> $vmfFile

		Name                           Value
		----                           -----
		properties                     {}
		classes                        {[world, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]], [entity, System.Collecti…

	PS> $lmpFile

		Name                           Value
		----                           -----
		header                         {[Offset, 20], [Id, 0], [Version, 0], [Length, 600261]…}
		data                           {[hammerid-1, System.Collections.Specialized.OrderedDictionary], [hammerid-162364, System.Collections.…

	PS> $vmfMerged = Merge-Map -Vmf $lmpFile -Lmp $lmpFile
	PS> Export-Vmf -InputObject $vmfMerged -Path ".\c5m3_cemetery_d_2.vmf"

	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
	PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
	PS> $stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
	PS> $vmfFile

		Name                           Value
		----                           -----
		properties                     {}
		classes                        {[world, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]], [entity, System.Collecti…

	PS> $lmpFile

		Name                           Value
		----                           -----
		header                         {[Offset, 20], [Id, 0], [Version, 0], [Length, 600261]…}
		data                           {[hammerid-1, System.Collections.Specialized.OrderedDictionary], [hammerid-162364, System.Collections.…

	PS> $stripperFile

		Name                           Value
		----                           -----
		properties                     {}
		modes                          {[filter, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]]…

	PS> $stripperFile["modes"]
	
		Name                           Value
		----                           -----
		filter                         {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …
		add                            {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …
		modify                         {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …

	PS> $stripperFile["modes"]["add"][2]["properties"]

		Name                           Value
		----                           -----
		solid                          {6}
		origin                         {7372 -8456 102}
		angles                         {0 90 0}
		model                          {models/props_urban/gate_wall001_256.mdl}
		classname                      {prop_dynamic}
		disableshadows                 {1}

	PS> $stripperFile["modes"]["add"][2]["properties"]["disableshadows"]

	1
	PS>	$stripperFile["modes"]["add"][2]["properties"]["disableshadows"].GetType()

		IsPublic IsSerial Name                                     BaseType
		-------- -------- ----                                     --------
		True     True     List`1                                   System.Object

	PS> $stripperFile["modes"]["add"][2]["properties"]["disableshadows"][0] = 0
	PS> $stripperFile["modes"]["add"][2]["properties"]

		Name                           Value
		----                           -----
		solid                          {6}
		origin                         {7372 -8456 102}
		angles                         {0 90 0}
		model                          {models/props_urban/gate_wall001_256.mdl}
		classname                      {prop_dynamic}
		disableshadows                 {0}

	PS> $vmfMerged = Merge-Map -Vmf $lmpFile -Lmp $lmpFile -Stripper $stripperFile
	PS> Export-Vmf -InputObject $vmfMerged -Path ".\c5m3_cemetery_d_2.vmf"

	.EXAMPLE
	PS> $vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
	PS> $lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
	PS> $stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
	PS> $vmfMerged = Merge-Map -Vmf $lmpFile -Lmp $lmpFile -Stripper $stripperFile
	PS> Export-Vmf -InputObject $vmfMerged -Path ".\c5m3_cemetery_d_2.vmf"
#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[System.Collections.IDictionary]$Vmf,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[System.Collections.IDictionary]$Lmp,

		[Parameter(Position = 2,
		Mandatory = $false)]
		[System.Collections.IDictionary]$Stripper,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent,

		[System.Management.Automation.SwitchParameter]$Demo
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
		if ($Vmf -and
			$Vmf.GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]) ) {
			Write-Debug "Input: $($Vmf.GetType().FullName)"
		} else {
			Write-Error "Vmf does not contain data hashtable"
			Throw "$($MyInvocation.MyCommand): $($PSItem)"
		}
		if ($Lmp -and
			$Lmp.GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]) ) {
			Write-Debug "Input: $($Lmp.GetType().FullName)"
			if (-not ($Lmp.Contains("header") -and
			$Lmp["header"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]))) {
				# Header will be recreated
				Write-Debug "Input hashtable does not contain header"
				# Write-Error "Input hashtable does not contain header"
				# Throw "$($MyInvocation.MyCommand): $($PSItem)"
			}
			if ((-not $Lmp.Contains("data") -and
			$Lmp["data"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary]))) {
				# Write-Debug "Lmp does not contain data hashtable"
				# Write-Debug "Lmp is assumed to be only containing data"
				Write-Error "Lmp does not contain data hashtable"
				Throw "$($MyInvocation.MyCommand): $($PSItem)"
			}
		}
		#endregion
		$LogFile = $(Get-AbsolutePath -Path $LogFile)	# Just a precaution

		#region Visgroups
		# Ensure it does exist
		if (-not $Vmf["classes"].Contains("visgroups") -or -not $Vmf["classes"]["visgroups"].get_Count() -gt 0) {
			$success = New-VmfVisgroupsContainer -Vmf $Vmf			# Ensure the main wrapper class exists
		}

		$params = @{
			Vmf		= $Vmf
			LogFile	= $LogFile
			Silent	= $Silent.IsPresent
		}
		$visgroupidMax = Get-MaxVisgroupid @params

		$visgroupidTable	= @{
			vmfMax		= $visgroupidMax
			current		= $visgroupidMax + 1
		}
		$colorsTable	= Get-ColorsTable

		$params = @{
			VmfSection		= $Vmf["classes"]["visgroups"][0]
			Name			= "Custom"
			Color			= $colorsTable["DarkGrey"]
			VisgroupidTable	= $visgroupidTable
		}
		$visgroups			= New-VmfVisgroupWrapper @params
		#endregion

		$vmfMerged = $Vmf						# This is the structure we'll be working with
		if ($PSBoundParameters.ContainsKey('Lmp')) {
			$params = @{
				Vmf				= $vmfMerged
				Lmp				= $Lmp
				VisgroupidTable	= $visgroupidTable
				Visgroups		= $visgroups
				LogFile			= $LogFile
				Silent			= $Silent.IsPresent
				Demo			= $Demo.IsPresent
			}
			$vmfMerged = Merge-VmfLmp @params
		}
		if ($PSBoundParameters.ContainsKey('Stripper')) {
			$params = @{
				Vmf				= $vmfMerged
				Stripper		= $Stripper
				VisgroupidTable	= $visgroupidTable
				Visgroups		= $visgroups
				LogFile			= $LogFile
				Silent			= $Silent.IsPresent
				Demo			= $Demo.IsPresent
			}
			$vmfMerged = Merge-VmfStripper @params
		}
		
		return $vmfMerged
		
		if (-not $Silent.IsPresent) {
			Out-Log -Value "`nMap Merger | Merging files: Complete `n" -Path $LogFile -OneLine
			Out-Log -Property "VMF merged type" -Value $vmfMerged.GetType().FullName -Path $LogFile
		}
	}

	END { }
}