function ConvertFrom-Ini {
	# This function basically does all the heavy lifting for this module. 'Import-Ini' is only a wrapper for this one
	# Use 'help Import-Ini' to learn more
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		[string]$Path,

		[Parameter(Position = 1)]
		[string]$IgnoreCommentsPattern
	)

	#region VARIABLES
	$defaultSectionName		= "Global"
	$settings				= [ordered]@{ $defaultSectionName = [ordered]@{} }	# Stores key-value pairs
	$comments				= @{ $defaultSectionName = @{} }					# Stores comments 
	[int]$sectionCount		= 0
	[string]$currentSection = $defaultSectionName
	[string]$currentComment = $defaultSectionName
	[string]$currentLine	= ""
	[Int16]$linesCount		= 0
	[Int16]$linesFaulty		= 0
	[bool]$isFirstLine		= $true
	#endregion

	# $sw = [System.Diagnostics.Stopwatch]::StartNew()

	# A hashtable for regex matches. 
	# Note that the comments are also captured and stored in a separate hashtable.
	$regex = Get-IniRegex

	try {
		switch -regex -file $Path {
			# Empty line
			# Could also use 'default' to manage this case
			# Although it helps skipping the expensive checks earlier
			"$($regex.emptyLine)" {
				$linesCount++
				$currentLine = $PSItem
				# Write-Debug "----Empty line----"
				continue
			}

			# A single-line comment
			# It's stored in a separate, unordered hashtable and is later put back into the file
			"$($regex.comment)" {
				$linesCount++
				$currentLine = $PSItem
				$params = @{
					Settings				= $settings
					Comments				= $comments
					CurrentSection			= [ref]$currentSection
					CurrentComment			= [ref]$currentComment
					IsFirstLine				= [ref]$isFirstLine
					IgnoreCommentsPattern	= [ref]$IgnoreCommentsPattern
				}
				ValidateIniComment @Params
				# Write-Debug "----Comment----"
				# Write-Verbose "Comment`t| $_"
				continue
			}

			# Section
			# An empty section is given a generated name that looks like this: [Section_X],
			# Where 'X' is an ID 
			"$($regex.section)" {
				$linesCount++
				$currentLine = $PSItem
				$params = @{
					Settings		= $settings
					Comments		= $comments
					CurrentSection	= [ref]$currentSection
					CurrentComment	= [ref]$currentComment
					IsFirstLine		= [ref]$isFirstLine
					SectionCount	= [ref]$sectionCount
				}
				ValidateIniSection @params
				# Write-Debug "----Section----"
				# Write-Verbose "Section`t| $_"
				continue
			}

			# No value line (but with a valid key)
			"$($regex.invalidValue)" {
				$linesCount++
				$currentLine = $PSItem
				$params = @{
					Settings		= $settings
					Comments		= $comments
					CurrentSection	= [ref]$currentSection
					CurrentComment	= [ref]$currentComment
					IsFirstLine		= [ref]$isFirstLine
				}
				ValidateIniInvalidValue @params
				# Write-Debug "----A line with no value----"
				# Write-Verbose "No value`t| $_"
				continue
			}

			# Assumed Key-Value pair
			# The logic is pretty fucked up
			"$($regex.keyValue)" {
				$linesCount++
				$currentLine = $PSItem
				$params = @{
					Settings		= $settings
					Comments		= $comments
					CurrentSection	= [ref]$currentSection
					CurrentComment	= [ref]$currentComment
					IsFirstLine		= [ref]$isFirstLine
				}
				ValidateIniKeyValue @params
				# Write-Debug "----Key-value pair----"
				# Write-Debug "$_"
				continue
			}

			default {
				$linesCount++
				$linesFaulty++
				$currentLine = $PSItem
				Write-Verbose	"An unidentified content on line $($linesCount): $_"
				if (-not $PSBoundParameters.ContainsKey('Verbose')) {
					Write-Debug	"UNDEFINED (line $linesCount): $_"
				}
			}
		}

		# $sw.Stop()
		# Write-Host "Elapsed time: $($sw.Elapsed)"

		if ($VerbosePreference -ne "SilentlyContinue"){
			ReportStatistics -LinesCount $linesCount -LinesFaulty $linesFaulty
		}

		# MAIN EXIT ROUTE
		return @{ settings = $settings; comments = $comments}

	} catch [System.IO.FileNotFoundException], [System.IO.IOException] {
		Write-Error -Message "$($MyInvocation.MyCommand): File is corrupted or doesn't exist!"
		Write-HostError -ForegroundColor DarkYellow "Check the spelling of the filename before using it explicitly."
		Throw $_.Exception
	} catch {
		Write-Error "$($MyInvocation.MyCommand): Error processing the input file."
		if (				 $null	-ne $linesCount	-and
			$ErrorActionPreference	-ne "Ignore"	-and
			$ErrorActionPreference	-ne "SilentlyContinue") {
			ReportLine -Path (Resolve-Path $Path) -CurrentLine $currentLine -LinesCount $linesCount
		}
		Throw $_.Exception
	}
}