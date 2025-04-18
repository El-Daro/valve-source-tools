function Export-Ini {
<#
	.SYNOPSIS
	Converts a hashtable into an .ini file format string and outputs it in a file, if specified.

	.DESCRIPTION
	Converts a hashtable into a single string, formatted specifically for .ini files.

	This function is designed to work with ordered and unordered hashtables.
	When used in conjuction with `Input-Ini`, it will automatically detect the inner `settings` and `comments` hashtables.
	The `settings` hashtable represents the sections, and the `comments` hashtable represents the comments.
	If the automatic detection fails, the input is treated as a hashtable that contains sections of the .ini format.

	.PARAMETER InputObject
	The object to convert. It can be ordered or unordered hashtable. If the hashtable contains `settings` and `comments`
	as inner hashtables, the input object is treated as a container for the two. If you happen to have an .ini file
	with the section of the same name, use `-Settings` parameter instead and pass the object as a whole.

	.PARAMETER Settings
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing sections of the .ini format. When used with the `Input-Ini` function, address the inside `settings`
	hashtable before using it with this parameter (e.g. $iniParsed["settings"]).

	.PARAMETER Comments
	The object to convert. It can be ordered or unordered hashtable. The content is invariably treated as a hashtable
	containing sections, each being its own hashtable with single-line and in-line comments of the .ini format.
	Each comment is addressed by a virtual 'key'. See NOTES for more info.
	When used with the `Input-Ini` function, address the inside `comments` hashtable before using it with this parameter (e.g. $iniParsed["comments"]).
	If this parameter is ommitted, the output won't have any comments.

	.PARAMETER Path
	Specifies the path to the output .ini file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER Force
	If specified, forces the over-write of an existing file. This paramater has no effect, if `-Path` parameter was not specified.

	.PARAMETER PassThru
	If specified, returns the resulting .ini formatted string even if `-Path` parameter was used.

	.INPUTS
	System.Collections.IDictionary
		Both ordered and unordered hashtables are valid inputs. You can pipe a string containing one of them to this function.

	.OUTPUTS
	System.String
		Note that by default this function returns only the .ini formatted string. If you want to output to a file instead,
		use the `-Path` parameter.

	.NOTES
	If the `comments` hashtable is detected, each comments is treated as one that is paired with a virtual 'key'.
	Comments can be single-line (SL), e.g occupying the whole line, or in-line (IL), e.g. following a key-value string.
	An in-line comment has the same key as `key-value` pair it relates to. The syntax for single-line comments differs.
	If an SL comment is preceeded by a valid Key-Value pair, the key is represented with `[<section-name>.<key>]` syntax.
	If an SL comment is preceeded by a valid section definition, the syntax is `[<section-name>.<section-name>]`.
	If an SL comment is not preceeded by anything or empty lines only, the virtual key is set to `[Global.Global]`.
	If you delete a key from the `settings` table before passing it to this function, the referenced comment won't be included.

	.LINK
	Import-Ini

	.LINK
	Export-Csv

	.LINK
	Export-CliXml
	
	.LINK
	about_Hash_Tables
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["settings"]["Main"]["LogDir"] = "c:\temp\"
	PS> Export-Ini -InputObject $iniFile -Path ".\settings_new.ini"

	Note that when the `-InputObject` parameter is used, it tries to locate `settings` and `comments` hashtable inside.
	If it fails to do so, the content is assumed to be the sections.
	By default the function does not over-write an existing file. Use the `-Force` parameter to change this behaviour. 
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["settings"]["Main"]["Logging"] = "false"
	PS> Export-Ini -Settings $iniFile["settings"] -Path ".\output.ini"

	You can also pass only the "settings" part in this function. In this case comments won't be included.
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["comments"]["Global"].Keys
	[Global.Global]
	PS> $iniFile["comments"]["Global"].Remove("[Global.Global]")
	PS> $iniFile["comments"]["Global"].Keys
	PS> Export-Ini -Settings $iniFile["settings"] -Comments $iniFile["comments"] -Path ".\settings_updated.ini"

	When working with the "comments" hashtable, note that single-line comments are groupped by one key even if they span across a few lines.
	A section with no definition is assumed to be "Global". If the "Global" section contains nothing, but commented lines,
	the comments are grouped under the "[Global.Global]" key. If you have a named section ("Main", for example)
	a single-line comment following the definition of the section is given the key "[Main.Main]".
	If a comment is preceeded by a valid Key-Value pair, the key is represented with "[<section-name>.<key>]" syntax.
	An in-line comment is accessable by the same key as the key-value pair it references to.
	
	.EXAMPLE
	PS> Import-Ini -Path ".\settings.ini" -IgnoreCommentsPattern "^##.*##`$" | Export-Ini -Path ".\settings_updated.ini"

	You can also pipe an object to this function.
#>
	[CmdletBinding(DefaultParameterSetName="HashtableDouble")]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ParameterSetName = 'HashtableSingle',
		ValueFromPipeline = $true)]
		[System.Collections.IDictionary]$InputObject,

		[Parameter(Position = 0,
		Mandatory = $true,
		ParameterSetName = 'HashtableDouble')]
		[System.Collections.IDictionary]$Settings,

		[Parameter(Position = 1,
		ParameterSetName = 'HashtableDouble')]
		[System.Collections.IDictionary]$Comments,

		[string]$Path,

		[System.Management.Automation.SwitchParameter]$Force = $False,

		[System.Management.Automation.SwitchParameter]$PassThru = $False,

		[Parameter(DontShow)]
		[string]$DebugOutput = ".\output_debug.ini"
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
		if ($Settings) {
			Write-Debug "Settings are passed: $($Settings.GetType().FullName)"
		}
		if ($Comments) {
			Write-Debug "Comments are passed: $($Comments.GetType().FullName)"
		}
		# Convert input object into two hashtables, if valid
		if ($InputObject) {
			Write-Debug "Input-Object is passed"
			try {
				if ($InputObject.Contains("settings") -and
				$InputObject["settings"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary])) {
					# If 'InputObject' has 'settings' as a hashtable/ordered dictionary, reassign it to 'Settings' 
					$Settings = $InputObject["settings"]
					Write-Debug "`$Settings: $($Settings.GetType().FullName)"
				} else {
					$Settings = $InputObject
					break
				}
				if ($InputObject.Contains("comments") -and
				$InputObject["comments"].GetType().ImplementedInterfaces.Contains([System.Collections.IDIctionary])) {
					# If 'InputObject' has 'comments' as a hashtable/ordered dictionary, reassign it to 'Comments' 
					$Comments = $InputObject["comments"]
					Write-Debug "`$Comments: $($Comments.GetType().FullName)"
				}
			} catch {
				Write-Debug "Something is seriously wrong with the input, go get some sleep, my little coder"
				return $False
			}
		}
		#endregion

		$ini = ConvertTo-Ini -Settings $Settings -Comments $Comments

		$params = @{
			Content		= $ini
			Path		= $Path
			Force 		= $Force
			PassThru	= $PassThru
			Extension	= ".ini"
			DebugOutput	= $DebugOutput
		}
		Out-Config @params
	}

	END { }
}