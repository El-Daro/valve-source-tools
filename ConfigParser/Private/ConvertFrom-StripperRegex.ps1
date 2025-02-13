# Next: preserving comments for future use 

using namespace System.Diagnostics

function ConvertFrom-StripperRegex {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	#region Preparing shared variables
	$linesFaulty		= 0
	$currentLine		= 0
	$currentMode		= 'filter'		# filter=remove | add | modify=replace
	$currentSubmode		= 'none'		# none | match | replace | delete=remove | insert
	$currentBlock		= [ordered]@{
		properties	= [ordered]@{};
		modes		= [ordered]@{}
	}
	$stripper			= [ordered]@{	# This gets populated with currentBlock on bracket close
		properties		= [ordered]@{};
		modes			= [ordered]@{
			filter	= [System.Collections.Generic.List[ordered]]::new()
			add		= [System.Collections.Generic.List[ordered]]::new()
			modify	= [System.Collections.Generic.List[ordered]]::new()
		}
	}
	$stackBlocks		= [System.Collections.Generic.Stack[ordered]]::new()
	$progressCounter	= 0
	$progressStep		= [math]::Ceiling($Lines.Count / 5)
	$regex				= Get-StripperRegex
	#endregion

	try  {

		$sw = [Stopwatch]::StartNew()
		
		while ($currentLine -lt $Lines.count) {
			# Write-Debug "$($currentLine + 1): $Lines[$currentLine]"
			$line = $Lines[$currentLine].Trim()
			if ($line.Length -lt 1) {
				$currentLine++
				continue
			}

			switch -regex ($line) {
				# A key-value pair
				"$($regex.keyValue)" {
					$key	= $Matches["key"]
					$value	= $Matches["value"]
					if (-not $currentBlock["properties"].Contains($key)) {
						$currentBlock["properties"][$key] = [System.Collections.Generic.List[string]]::new()
					}
					$currentBlock["properties"][$key].Add($value)
					break
				}

				# An open bracket
				"$($regex.bracketOpen)" {
					$Depth++
					if ($Depth -gt 1) {
						$stackBlocks.Push($currentBlock)
					}
					if ($currentMode -eq "modify" -and $Depth -eq 1) {
						$currentBlock	= [ordered]@{
							properties	= [ordered]@{};
							modes		= [ordered]@{
								match	= [System.Collections.Generic.List[ordered]]::new();
								replace	= [System.Collections.Generic.List[ordered]]::new();
								delete	= [System.Collections.Generic.List[ordered]]::new();
								insert	= [System.Collections.Generic.List[ordered]]::new()
							}
						}
					} else {
						$currentBlock	= [ordered]@{
							properties	= [ordered]@{};
							modes		= [ordered]@{}
						}
					}
					break
				}

				# A close bracket
				"$($regex.bracketClose)" {
					$Depth--
					if ($Depth -lt 0) {
						Write-Debug "Unexpected '}'"
						continue
					}
					if ($currentMode -eq "modify" -and $Depth -ne 0) {		# If we are in the modify block and just populated a new block
						$parentBlock = $stackBlocks.Pop()					# Return one level up
						# Initial implementation:
						# $parentBlock[$currentSubmode] = $currentBlock		# Add the newly populated block
						$parentBlock["modes"][$currentSubmode].Add($currentBlock)	# Add the newly populated block
						$stackBlocks.Push($parentBlock)						# And push it back to the stack
						# $currentSubmode = "none"
					} else {
						$stripper["modes"][$currentMode].Add($currentBlock)
					}
					if ($Depth -gt 0 -and $stackBlocks.Count -gt 0) {
						$currentBlock = $stackBlocks.Pop()
					}
					break
				}

				"$($regex.comment)" {
					# Comments are ignored (for now)
					break
				}

				# Mode identificator
				"$($regex.mode)" {
					$currentMode = $Matches["mode"]
					break
				}

				# Sub-mode identificator
				"$($regex.subMode)" {
					if ($currentMode -ne "modify") {
						# Ignore? currentMode should point to "none"
						# The hashtable will still be populated, but it will be ignored later during the processing
						Write-Debug "A sub-mode was announced not in a proper mode (modify)"
						Write-Debug "Current mode: $currentMode"
					} else {
						$currentSubmode	= $Matches["subMode"]
					}
					break
				}

				default {
					if ($line -notmatch "$($regex.emptyLine)") {
						$linesFaulty++
						Write-Verbose "An unidentified content on line $($currentLine + 1): $line"
						if (-not $PSBoundParameters.ContainsKey('Verbose')) {
							Write-Debug "UNDEFINED (line $($currentLine + 1)): $line"
						}
					}
					break
				}
			}

			$CurrentLine += 1
	
			if ($Lines.Count -gt 10000 -and $currentLine -ge $progressStep -and [math]::Floor($currentLine / $progressStep) -gt $progressCounter) { 
				$progressCounter++
				$elapsedMilliseconds = $sw.ElapsedMilliseconds
				$estimatedMilliseconds = ($Lines.Count / $currentLine) * $elapsedMilliseconds
				$params = @{
					CurrentLine				= $currentLine
					LinesCount				= $Lines.count
					EstimatedMilliseconds	= $estimatedMilliseconds
					ElapsedMilliseconds		= $sw.ElapsedMilliseconds
					Activity				= "Parsing..."
				}
				ReportProgress @params
			}
	
		}

		# MAIN EXIT ROUTE
		return $stripper

	} catch [FormatException] {
		Write-Error -Message "$($_.Exception.Message)"
		Write-HostError -ForegroundColor DarkYellow -NoNewline "`tCheck the file "
		Write-HostError -ForegroundColor Cyan -NoNewline "`"$(Get-AbsolutePath -Path $Path)`" "
		Write-HostError -ForegroundColor DarkYellow "for any missing curly brackets or bracket keys."
		Throw $_.Exception
	} catch {
		Write-Error "$($MyInvocation.MyCommand): Error processing the input file."
		if (				 $null	-ne $currentLine -and
			$ErrorActionPreference	-ne "Ignore"	-and
			$ErrorActionPreference	-ne "SilentlyContinue") {
			ReportLine -Path (Resolve-Path $Path) -CurrentLine $Lines[$currentLine] -LinesCount $currentLine
		}
		Throw $_.Exception
	} finally {
		$sw.Stop()

		if (-not $Silent.IsPresent) {
			$linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			OutLog 							-Value "`nStripper | Parsing: Complete"					-Path $LogFile -OneLine
			OutLog -Property "Parsed lines"	-Value $("{0} / {1}" -f $currentLine, $Lines.Count)		-Path $LogFile
			if ($linesFaulty -gt 0) {
				OutLog -Property "Faulty lines"	-Value $("{0} / {1}" -f $linesFaulty, $Lines.Count)	-Path $LogFile
			}
			OutLog -Property "Elapsed time"	-Value $timeFormatted									-Path $LogFile
			OutLog -Property "Speed"		-Value $("{0:n0} lines per second" -f $linesPerSecond)	-Path $LogFile
		}
	}
}