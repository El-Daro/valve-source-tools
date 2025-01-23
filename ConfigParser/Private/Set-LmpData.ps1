# Returns .lmp data as a byte array

using namespace System.Diagnostics

function Set-LmpData {
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true)]
		$Lmp,

		[Parameter(Position = 1,
		Mandatory = $false,
		ValueFromPipeline = $false)]
		$EstimatedSections,
			
		[Parameter(Position = 2,
		Mandatory = $false)]
		[ref]$StopWatch,

		[Parameter(Position = 3,
		Mandatory = $false)]
		[string]$LogFile,

		[System.Management.Automation.SwitchParameter]$Silent
	)

	try {

		if (-not $PSBoundParameters.ContainsKey($Size) -or $null -eq $Size) {
			$Size = 4
		}
		$progressStep		= $EstimatedSections / 10
		$progressCounter	= 0

		# Note: using an Int32 as a constructor parameter will define the starting capacity (def.: 16)
		$stringBuilder = [System.Text.StringBuilder]::new(256)
		$sectionsCount = 0
		$sw = [Stopwatch]::StartNew()

		foreach ($section in $Lmp["data"].Keys) {
			[void]$stringBuilder.AppendFormat('{0}{1}', "{", "`n")
			foreach ($propertyName in $Lmp["data"][$section].Keys) {
				foreach ($propertyValue in $Lmp["data"][$section][$propertyName]) {
					[void]$stringBuilder.AppendFormat('{0}"{1}" "{2}"{3}', $tabsKey, $propertyName, $propertyValue, "`n")
				}
			}
			[void]$stringBuilder.AppendFormat('{0}{1}', "}", "`n")
			$sectionsCount++

			if ($EstimatedSections -gt 0 -and ($sectionsCount -gt $ProgressStep -and [math]::Floor($sectionsCount / $ProgressStep) -gt $progressCounter)) {
				$elapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
				$estimatedMilliseconds		= ($EstimatedSections / $sectionsCount) * $elapsedMilliseconds
				$params = @{
					CurrentLine				= $sectionsCount
					LinesCount				= $EstimatedSections
					EstimatedMilliseconds	= $estimatedMilliseconds
					ElapsedMilliseconds		= $StopWatch.Value.ElapsedMilliseconds
					Activity				= "Building..."
				}
				ReportProgress @params
				$progressCounter++
			}
		}

		$sw.Stop()
		
		# $data = [System.Text.Encoding]::UTF8.GetBytes($StringBuilder.ToString().Trim())
		# $data += 0x0A
		# $data += 0x00
		# return [byte[]]$data

		return $StringBuilder.ToString().Trim()

	} catch {
		Write-Debug "LUMP data is corrupted"
		Write-Error -Message "$($MyInvocation.MyCommand):  $($_.Exception.Message)"
		return $False
	} finally {

	}
}