using namespace System.Diagnostics

function ConvertFrom-Lmp {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines,

		[Parameter(Position = 1,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	#region Variables
	$linesFaulty			= 0
	$currentLine			= 0
	$sections				= [ordered]@{ }
	$currentBlock			= [ordered]@{ }
	$sectionsCounter		= 0
	$progressCounter		= 0
	$progressStep			= [math]::Ceiling($Lines.Count / 10)
	#endregion

	try  {

		$sw = [Stopwatch]::StartNew()

		while ($currentLine -lt $Lines.count) {
	
			$line = $Lines[$currentLine].Trim()
			if ($line[0] -eq "`"") {
				# If line starts with double quote, it's a property
				$property		= $line.SubString(1, $line.Length - 2) -split "`" `""
				if (-not $currentBlock.Contains($property[0])) {
					$currentBlock[$property[0]] = [System.Collections.Generic.List[string]]::new()
				}
				$currentBlock[$property[0]].Add($property[1])
	
			} elseif ($line[0] -eq "}") {
				if ($currentBlock.Contains("hammerid")) {
					$key	= "hammerid-" + $currentBlock["hammerid"][0]
				} elseif ($currentBlock.Contains("classname")) {
					# Unfortunately, this route is possible. Gonna have to add it as a classname (might override previous)
					$key	= "classname-" + $currentBlock["classname"][0]
					Write-Debug "Line $($currentLine): No hammerid was found. Adding as a classname"
				} else {
					Write-Debug "Line $($currentLine): No hammerid or classname was found. Adding as 'unknown-line-$currentLine'"
					Out-Log	-Value "Unknown section exit on line $currentLine" -Path $LogFile -OneLine
					foreach ($property in $currentBlock.Keys) {
						Out-Log	-Property $property	-Value $currentBlock[$property]	-Path $LogFile
					}
					Out-Log	-Value "Unknown section dump end" -Path $LogFile -OneLine
					$key 	= "unknown-line-$currentLine"
				}
				$sections.Add($key, $currentBlock)
				
			} elseif ([string]::IsNullOrWhiteSpace($line) -or $line[0] -eq "/") {
				$linesFaulty++
				Write-Debug "Line $($currentLine): Empty line or a comment"

			} else {
				$sectionsCounter++
				$currentBlock = [ordered]@{ }
			}

			
			$currentLine += 1
	
			if ($currentLine -ge $progressStep -and [math]::Floor($currentLine / $progressStep) -gt $progressCounter) { 
				$progressCounter++
				$elapsedMilliseconds = $StopWatch.ElapsedMilliseconds
				$estimatedMilliseconds = ($Lines.Count / $currentLine) * $elapsedMilliseconds
				$params = @{
					currentLine				= $currentLine
					LinesCount				= $Lines.count
					EstimatedMilliseconds	= $estimatedMilliseconds
					ElapsedMilliseconds		= $StopWatch.ElapsedMilliseconds
					Activity				= "Parsing..."
				}
				ReportProgress @params
			}
	
		}
		return $sections

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
			Out-Log 								-Value "`nLMP | Parsing: Complete"						-Path $LogFile -OneLine
			Out-Log -Property "Parsed lines"		-Value $("{0} / {1}" -f $currentLine, $Lines.Count)		-Path $LogFile
			if ($linesFaulty -gt 0) {
				Out-Log -Property "Faulty lines"	-Value $("{0} / {1}" -f $linesFaulty, $Lines.Count)		-Path $LogFile
			}
			Out-Log -Property "Elapsed time"		-Value $timeFormatted									-Path $LogFile
			Out-Log -Property "Speed"			-Value $("{0:n0} lines per second" -f $linesPerSecond)	-Path $LogFile
		}
	}
}