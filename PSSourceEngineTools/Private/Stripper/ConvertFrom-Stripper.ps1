using namespace System.Diagnostics

function ConvertFrom-Stripper {
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
			filter	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
			add		= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
			modify	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
		}
	}
	# $stackBlocks		= [System.Collections.Generic.Stack[ordered]]::new()
	$stackBlocks		= [Collections.Generic.Stack[Collections.Specialized.OrderedDictionary]]::new()
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

			if ($line[0] -eq "`"") {
				# Key-value
				if ($line -match "$($regex.keyValue)") {
					$key	= $Matches["key"]
					$value	= $Matches["value"]
					if (-not $currentBlock["properties"].Contains($key)) {
						$currentBlock["properties"][$key] = [System.Collections.Generic.List[string]]::new()
					}
					$currentBlock["properties"][$key].Add($value)
				}

			} elseif ($line[0] -eq '{') {
				$Depth++
				if ($Depth -gt 1) {
					$stackBlocks.Push($currentBlock)
				}
				if ($currentMode -eq "modify" -and $Depth -eq 1) {
					$currentBlock	= [ordered]@{
						properties	= [ordered]@{};
						modes		= [ordered]@{
							match	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new();
							replace	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new();
							delete	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new();
							insert	= [Collections.Generic.List[Collections.Specialized.OrderedDictionary]]::new()
						}
					}
				} else {
					$currentBlock	= [ordered]@{
						properties	= [ordered]@{};
						modes		= [ordered]@{}
					}
				}

			} elseif ($line[0] -eq '}') {
				$Depth--
				if ($Depth -lt 0) {
					Write-Debug "Unexpected '}'"
					continue
				}
				if ($currentMode -eq "modify" -and $Depth -ne 0) {		# If we are in the modify block and just populated a new block
					$parentBlock = $stackBlocks.Pop()					# Return one level up
					$parentBlock["modes"][$currentSubmode].Add($currentBlock)	# Add the newly populated block
					$stackBlocks.Push($parentBlock)						# And push it back to the stack
				} else {
					$stripper["modes"][$currentMode].Add($currentBlock)
				}
				if ($Depth -gt 0 -and $stackBlocks.Count -gt 0) {
					$currentBlock = $stackBlocks.Pop()
				}

			} elseif (($line[0] -eq ';') -or
					  ($line[0] -eq '#') -or
					  ($line.Length -gt 1 -and $line[0] -eq '/' -and $line[1] -eq '/')) {
	  			# Comments are ignored (for now)
				
			} else {
				if ($line -match "$($regex.mode)") {
					$currentMode = $Matches["mode"]
				} elseif ($line -match "$($regex.subMode)") {
					if ($currentMode -ne "modify") {
						# Ignore? currentMode should point to "none"
						# The hashtable will still be populated, but it will be ignored later during the processing
						Write-Debug "A sub-mode was announced not in a proper mode (modify)"
						Write-Debug "Current mode: $currentMode"
					} else {
						$currentSubmode	= $Matches["subMode"]
					}
				} else {
					$linesFaulty++
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
			if ($sw.ElapsedMilliseconds -gt 0) {
				$linesPerSecond = ($currentLine / $sw.ElapsedMilliseconds) * 1000
			} else {
				$linesPerSecond = $currentLine * 1000
			}
			$timeFormatted = "{0}m {1}s {2}ms" -f
				$sw.Elapsed.Minutes, $sw.Elapsed.Seconds, $sw.Elapsed.Milliseconds
			Out-Log 							-Value "`nStripper | Parsing: Complete"					-Path $LogFile -OneLine
			Out-Log -Property "Parsed lines"	-Value $("{0} / {1}" -f $currentLine, $Lines.Count)		-Path $LogFile
			if ($linesFaulty -gt 0) {
				Out-Log -Property "Faulty lines"	-Value $("{0} / {1}" -f $linesFaulty, $Lines.Count)	-Path $LogFile
			}
			Out-Log -Property "Elapsed time"	-Value $timeFormatted									-Path $LogFile
			Out-Log -Property "Speed"		-Value $("{0:n0} lines per second" -f $linesPerSecond)	-Path $LogFile
		}
	}
}