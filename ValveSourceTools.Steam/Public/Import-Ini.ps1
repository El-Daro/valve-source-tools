function Import-Ini {
<#
	.SYNOPSIS
	Reads an .ini file and creates two corresponding objects: one for the settings and one for the comments

	.DESCRIPTION
	Reads through an .ini file and populates an ordered hashtable with sections that contain relative Key-Value pairs.

	A second hashtable (unordered) is created solely for the comments, each paired with a virtual 'key'.
	Comments can be single-line (SL), e.g occupying the whole line, or in-line (IL), e.g. following a key-value string.
	An in-line comment has the same key as `key-value` pair it relates to. The syntax for single-line comments differs.
	If an SL comment is preceeded by a valid Key-Value pair, the key is represented with `[<section-name>.<key>]` syntax.
	If an SL comment is preceeded by a valid section definition, the syntax is `[<section-name>.<section-name>]`.
	If an SL comment is not preceeded by anything or empty lines only, the virtual key is set to `[Global.Global]`.
	If a few SL comments are occupying different lines, they are grouped under the same key.
	If you delete a key from the `settings` table before passing it to the `Export-Ini` function,
	the referenced comment won't be included.

	.PARAMETER Path
	Specifies the path to the .ini file. Accepts absolute and relative paths. Does NOT accept wildcards.

	.PARAMETER IgnoreCommentsPattern
	Specifies a RegEx string for a specific comment pattern that has to be ignored. If you create your .ini files automatically, use
	a specific pattern for the comments that you include. For example, if you specify `"^#;.*;#`$"` with this parameter, a single-line
	comment string that starts with `#;` and ends with `;#` will be ingored and will not be included in the ouptut.
	When a common parameter `-Debug` is used, this parameter is assumed to be `"^#;.*;#`$"`, unless set explicitly by the caller.
	Use this parameter to prevent duplication of auto-generated comments.

	.INPUTS
	System.String
		You can pipe a string containing a path to this function.

	.OUTPUTS
	System.Collections.Hashtable
		Note that this function returns only one object:
			a hashtable that contains `settings` (System.Collections.Specialized.OrderedDictionary)
									and `comments` (System.Collections.Hashtable).

	.NOTES

	This function accepts sections denoted with `[` and `]`,
	valid key-value pairs and single-line or in-line comments starting with `;` or `#`.
	An empty line is ignored.
	A key cannot be empty or contain any of the following symbols: `[`, `]`, `;`, `#` and `=`.
	A value can be enclosed in single quotes (`' '`) or double quotes (`" "`).
	If a value is not enclosed in quotes, the comment characters (`;`, `#`) are not allowed inside
	and treated as comments on the first appearance. They are escaped otherwise.
	Poor syntax for the value can be forgiven, but in this case the function might yield unexpected results.
	It is up to the author of the .ini file to properly edit it.

	Note that this function returns only one object: a hashtable that contains `settings` and `comments` inside.
	When passed to `Export-Ini` function by the `-InputObject` parameter or through a pipeline,
	it 'unwraps' automatically, unless you change the names of the inner hashtables.

	.LINK
	Export-Ini

	.LINK
	Import-Csv

	.LINK
	Import-CliXml
	
	.LINK
	about_Hash_Tables
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile

	Name                           Value
	----                           -----
	comments                       {[Global, System.Collections.Hashtable], [Main, System.Collections.Hashtable]}
	settings                       {[Global, System.Collections.Specialized.OrderedDictionary], [Main, System.Collecti…
	
	PS> $iniFile["settings"]["Main"]

	Name                           Value
	----                           -----
	Logging                        true
	LogDir                         %UserProfile%\Documents\PowerShell\Logs
	
	PS> $iniFile["settings"]["Main"]["LogDir"]

	%UserProfile%\Documents\PowerShell\Logs
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["settings"]["Main"]["LogDir"] = "c:\temp\"
	PS> Export-Ini -InputObject $iniFile -Path "settings.ini" -Force

	Note that when the `-InputObject` parameter of the `Export-Ini` function is used,
	it tries to locate `settings` and `comments` hashtable inside.
	If it fails to do so, the content is assumed to be the sections.
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["settings"]["Main"]["Logging"] = "false"
	PS> Export-Ini -Settings $iniFile["settings"] -Path ".\settings_new.ini" 

	You can also pass only the "settings" part to the `Export-Ini` function. In this case comments won't be included.
	
	.EXAMPLE
	PS> $iniFile = Import-Ini -Path ".\settings.ini"
	PS> $iniFile["comments"]["Global"].Keys
	[Global.Global]
	PS> $iniFile["comments"]["Global"].Remove("[Global.Global]")
	PS> $iniFile["comments"]["Global"].Keys
	PS> Export-Ini -Settings $iniFile["settings"] -Comments $iniFile["comments"] -Path "settings_updated.ini"

	When working with the "comments" hashtable, note that single-line comments are groupped by one key even if they span across a few lines.
	A section with no definition is assumed to be "Global". If the "Global" section contains nothing, but commented lines,
	the comments are grouped under the "[Global.Global]" key. If you have a named section ("Main", for example)
	a single-line comment following the definition of the section is given the key "[Main.Main]".
	If a comment is preceeded by a valid Key-Value pair, the key is represented with "[<section-name>.<key>]" syntax.
	
	.EXAMPLE
	PS> Import-Ini "settings.ini" -IgnoreCommentsPattern "^##.*##`$" | Export-Ini -Path "settings_updated.ini"

	You can also pipe an object to the `Export-Ini` function.
#>
	
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[string]$Path,

		[Parameter(Position = 1)]
		[string]$IgnoreCommentsPattern
	)

	BEGIN {
		#region PREPARATIONS
		# Since this module is written directly in PowerShell,
		# the Common Parameters do not propagate, if this funciton is called from another module.
		# The code described in "PREPARATIONS" section is meant to fix this behaviour.
		# It is not necessary for any functions called from inside this module.
		# For more on this matter, see issue #4568 on GitHub: https://github.com/PowerShell/PowerShell/issues/4568 
		$prefVars = @{
			'ErrorActionPreference'	= 'ErrorAction'
			'DebugPreference'		= 'Debug'
			'VerbosePreference'		= 'Verbose'
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
						# Which asks for input every time it encounters a Write-Debug cmdlet
						$DebugPreference = 'Continue'
						if (-not $IgnoreCommentsPattern) {
							$IgnoreCommentsPattern = "^#;.*;#`$"
						}
						# Write-Debug "Preference variable $($entry.Key) was set to Continue"
					} else {
						Set-Variable -Name $callersVar.Name -Value $callersVar.Value -Force -Confirm:$false -WhatIf:$false
						# Write-Debug "Preference variable $($entry.Key) was set to $($callersVar.Value)"
					}
				}
			} elseif ($PSBoundParameters.ContainsKey('Debug')) {
				$DebugPreference = 'Continue'
				if (-not $IgnoreCommentsPattern) {
					$IgnoreCommentsPattern = "^#;.*;#`$"
				}
			}
		}

		if ($IgnoreCommentsPattern) {
			Write-Debug "The `$IgnoreCommentsPattern was passed. Validating..."
			try {
				"#; A simple test string ;#" -match $IgnoreCommentsPattern > $null
				Write-Debug "`tThe pattern is valid."
			} catch {
				Write-Host -ForegroundColor DarkYellow "`tAn incorrect regex pattern was passed for IgnoreCommentsPattern parameter."
				Write-Host -ForegroundColor DarkYellow "`tNo comments will be ignored during this process."
				Write-Debug "`tGo and test it on regex101.com before using it here, my little coder."
			}
		}
		#endregion
	}

	PROCESS {
		if (-not (Test-Path -Path $Path)) { 					# If file doesn't exist
			if (Test-Path -Path $($Path + ".ini")) {			# See if adding '.ini' actually helps
				$Path += ".ini"									# If so, add the extension and proceed with the converting
				Write-Debug "$($MyInvocation.MyCommand): No extension was provided. Adding one here"
			} else {
				Write-Error "$($MyInvocation.MyCommand): Could not find file '$(Get-AbsolutePath -Path $Path)'"
				Write-HostError  -ForegroundColor DarkYellow "Could not find the file. Check the spelling of the filename before using it explicitly."
				throw [System.IO.FileNotFoundException]	"Could not find file '$(Get-AbsolutePath -Path $Path)'"
			}
		} elseif ($Path -notmatch "^(?:.+)\.(ini|cfg)`"*'*`$") { # If file DOES exist, see if it is not an .ini one
			Write-Error "$($MyInvocation.MyCommand): File is not .ini: $(Get-AbsolutePath -Path $Path)"
			Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename and its extension."
			throw [System.IO.FileFormatException] "File format is incorrect: $(Get-AbsolutePath -Path $Path)"
		}
		Write-Verbose "The input path is correct. Processing..."
		Write-Debug "$($MyInvocation.MyCommand): Path: $(Get-AbsolutePath -Path $Path)"
		
		$params = @{
			Path					= $Path
			IgnoreCommentsPattern	= $IgnoreCommentsPattern
		}
		# All the logic is in this private function
		return ConvertFrom-Ini @params

	}

	END {}
}