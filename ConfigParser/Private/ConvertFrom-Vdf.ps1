# TODO: Revert back to VDF regex. Branch a VMX parser
# TODO: Revert everything back to VDF. This is strictrly VDF stuff (except leave optimisation in)

using namespace System.Diagnostics

function ConvertFrom-Vdf {
	Param (
		[Parameter(Position = 0,
		Mandatory = $true)]
		[string[]]$Lines
		# [System.String[]]$Lines
	)

	#region Preparing shared variables
	$linesFaulty	= 0
	$currentLine	= 0
	$currentKey		= ""
	$Depth			= 0
	$regex			= Get-VmfRegex			# TODO: Rever back to VDF regex. Branch a VMX parser
	#endregion

	try  {

		$sw = [Stopwatch]::StartNew()
		# All the logic is in this private function
		$params = @{
			Lines		= $Lines
			CurrentLine	= [ref]$currentLine
			LinesFaulty	= [ref]$linesFaulty
			Depth		= [ref]$Depth
			Regex		= $Regex			# It's a Dictionary, so you don't have to ref it
		}
		Write-Host  -ForegroundColor DarkYellow 	"Reading complete. Parsing..."
		return ValidateVdfBlock @params

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
		Write-Host "  Lines read: $currentLine / $($Lines.Count)" 
		ReportStatisticsVdf -LinesCount $Lines.Count -CurrentLine $currentLine
		Write-Host "Elapsed time: $($sw.Elapsed.Hours)h $($sw.Elapsed.Minutes)m $($sw.Elapsed.Seconds)s $($sw.Elapsed.Milliseconds)ms"
		# ReportLine -Path (Resolve-Path $Path) -CurrentLine $Lines[$currentLine] -LinesCount $currentLine
	}
}