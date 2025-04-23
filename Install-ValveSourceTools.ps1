# TODO: Improve logging to file

[CmdletBinding()]
Param (
	[Parameter(Position = 0,
	Mandatory = $false)]
	[string]$InstallPath,

	[Parameter(Position = 1,
	Mandatory = $false,
	ValueFromPipeline = $true)]
	[string]$RootPath,

	[Parameter(Position = 2)]
	[System.Management.Automation.SwitchParameter]$Silent,

	[Parameter(Position = 3,
	Mandatory = $false)]
	[string]$LogFile = ".\logs\install.log"

)

BEGIN {
	function Update-Directory {
		[CmdletBinding()]
		Param (
			[Parameter(Position = 0,
			Mandatory = $true)]
			[string]$Source,

			[Parameter(Position = 1,
			Mandatory = $true)]
			[string]$Destination,

			[Parameter(Position = 2)]
			[System.Management.Automation.SwitchParameter]$Silent
		)

		$Source			= $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Source)
		$Destination	= $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)

		if (-not (Test-Path -LiteralPath $Destination)) {
			$null = New-Item -Path $Destination -ItemType Directory
		}

		try {
			$sourceItem	= Get-Item -LiteralPath $Source
			$destItem	= Get-Item -LiteralPath $Destination

			if ($sourceItem -isnot [System.IO.DirectoryInfo] -or $destItem -isnot [System.IO.DirectoryInfo]) {
				throw 'Not a Directory Info'
			}
		} catch {
			if (-not $Silent.IsPresent) {
				Write-Host "Both Source and Destination must be directory paths."
			}
			return $false
		}

		$sourceFiles = Get-ChildItem -Path $Source -Recurse | Where-Object { -not $_.PSIsContainer }

		foreach ($sourceFile in $sourceFiles) {
			$relativePath	= Get-RelativePath $sourceFile.FullName -RelativeTo $Source
			$targetPath		= Join-Path -Path $Destination -ChildPath $relativePath

			$sourceHash		= Get-FileHash -Path $sourceFile.FullName
			$targetHash		= Get-FileHash -Path $targetPath

			if ($sourceHash -ne $targetHash) {
				$targetParent = Split-Path $targetPath -Parent

				if (-not (Test-Path -Path $targetParent -PathType Container)) {
					$null	= New-Item -Path $targetParent -ItemType Directory
				}

				Write-Verbose "Updating file $relativePath to new version"
				Copy-Item $sourceFile.FullName -Destination $targetPath -Force
			}
		}

		# NOTE: Maybe only remove outdated project files. Need a way to determine those
		#		It would probably be version based
		# $targetFiles = Get-ChildItem -Path $Destination -Recurse | Where-Object { -not $_.PSIsContainer }
		# foreach ($targetFile in $targetFiles) {
		# 	$relativePath = Get-RelativePath $targetFile.FullName -RelativeTo $Destination
		# 	$sourcePath = Join-Path -Path $Source -ChildPath $relativePath
		# 	if (-not (Test-Path $sourcePath -PathType Leaf)) {
		# 		Write-Verbose "Removing unknown file $relativePath from module folder."
		# 		Remove-Item -LiteralPath $targetFile.FullName -Force 
		# 	}
		# }

		return $true
	}

	function Get-RelativePath {
		Param (
			[string]$Path,

			[string]$RelativeTo
		)

		return $Path -replace "^$([regex]::Escape($RelativeTo))\\?"
	}

	function Get-FileHash {
		Param (
			[string]$Path
		)

		if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
			return $null
		}

		$item = Get-Item -LiteralPath $Path
		if ($item -isnot [System.IO.FileSystemInfo]) {
			return $null
		}

		$stream = $null

		try {
			$sha = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
			$stream = $item.OpenRead()
			$bytes = $sha.ComputeHash($stream)
			return [convert]::ToBase64String($bytes)
		} catch {
			# Do nothing
		} finally {
			if ($null -ne $stream) {
				$stream.Close()
			}
			if ($null -ne $sha)	{
				$sha.Clear()
			}
		}
	}

	function Show-HelpNonStandard {
		[CmdletBinding()]
		Param (
			[Parameter(Position = 0,
			Mandatory = $true)]
			[string[]]$Paths
		)

		Write-Host -ForegroundColor Yellow "`n  WARNING: Non-standard installation path(s) was used"
		foreach ($InstallPath in $InstallationPaths) {
			Write-Host -ForegroundColor DarkYellow -NoNewLine	"    Path: "
			Write-Host -ForegroundColor DarkCyan				"$InstallPath"
		}
		Write-Host -ForegroundColor Yellow					"`n  Add it to your profile or import the modules manually whenever you need them."
		Write-Host -ForegroundColor Yellow					"  - Adding a path to your profile:"
		Write-Host -ForegroundColor DarkYellow	-NoNewLine	"    1. Open "
		Write-Host -ForegroundColor DarkCyan				$("{0}" -f $profile.CurrentUserAllHosts)
		Write-Host -ForegroundColor DarkYellow				"    2. Add this and save the file:"
		Write-Host -ForegroundColor Cyan					"       `$Env:PSModulePath = `$Env:PSModulePath + [IO.Path]::PathSeparator + $($InstallationPaths[0])"
		Write-Host -ForegroundColor Yellow					"`n  - Importing modules manually:"
		Write-Host -ForegroundColor DarkYellow	-NoNewLine	"    Import-Module "
		Write-Host -ForegroundColor DarkCyan	-NoNewLine	$("{0}" -f $($InstallationPaths[0]) + [IO.Path]::DirectorySeparatorChar)
		Write-Host -ForegroundColor Magenta		-NoNewline	$("{0}" -f "<ModuleName>")
		Write-Host -ForegroundColor DarkCyan	-NoNewline	$("{0}" -f [IO.Path]::DirectorySeparatorChar)
		Write-Host -ForegroundColor Magenta		-NoNewline	$("{0}" -f "<ModuleName>")
		Write-Host -ForegroundColor DarkCyan 				$("{0}" -f ".psd1")
		Write-Host -ForegroundColor Yellow					"`n  Path to the installation folder was temporarily added to the current environment."
	}

	function Show-HelpSuccess {
		[CmdletBinding()]
		Param (
			# [Parameter(Position = 0,
			# Mandatory = $false)]
			# [string[]]$Paths
		)

		Write-Host -ForegroundColor Yellow "`n  Now you can use these PowerShell modules from anywhere in your system."
		Write-Host -ForegroundColor Yellow "  Learn more with these commands:"
		Write-Host -ForegroundColor Yellow	-NoNewLine	"    Get-Module "
		Write-Host -ForegroundColor Magenta	-NoNewLine	"<ModuleName> "
		Write-Host -ForegroundColor Yellow				"-ListAvailable"
		Write-Host -ForegroundColor Yellow	-NoNewLine	"    Get-Help "
		Write-Host -ForegroundColor Magenta	-NoNewLine	"<ModuleName> "
		Write-Host -ForegroundColor Yellow				"-Full"
	}

	function Show-HelpFailure {
		[CmdletBinding()]
		Param (
			# [Parameter(Position = 0,
			# Mandatory = $false)]
			# [string[]]$Paths
		)

		Write-Host -ForegroundColor Red		"`n  Failed to install PowerShell modules"
		Write-Host -ForegroundColor Yellow "  - Try running this script without any parameteres to install modules to default paths"
		Write-Host -ForegroundColor Yellow "  - Make sure this script is placed in the same folder as the modules. Example:"
		Write-Host -ForegroundColor DarkCyan	-NoNewLine	"  |-"
		Write-Host -ForegroundColor Magenta					"ValveSourceTools.<ModuleNameOne>"
		Write-Host -ForegroundColor DarkCyan	-NoNewLine	"  |-"
		Write-Host -ForegroundColor Magenta					"ValveSourceTools.<ModuleNameTwo>"
		Write-Host -ForegroundColor DarkCyan	-NoNewLine	"  |-"
		Write-Host -ForegroundColor Magenta					"..."
		Write-Host -ForegroundColor DarkCyan				"  |-$([IO.Path]::GetFileName($PSCommandPath))"
	}

	# This is necessary for Windows PowerShell (up to 5.1.3)
	# When the common parameter '-Debug' is used, Windows PowerShell sets the $DebugPreference to 'Inquire'
	# Which asks for input every time it encounters a Write-Debug cmdlet
	if ($PSBoundParameters.ContainsKey('Debug')) {
		$DebugPreference = 'Continue'
	}
	$ErrorActionPreference = 'Stop'
}

PROCESS {
	$oldPSModulePath	= $env:PSModulePath
	$nonStandardPath	= $false
	$LogFilePath		= $PSCmdlet.GetUnresolvedProviderPathFromPSPath($LogFile)
	# $baseLogName		= Join-Path -Path (Split-Path -Path $LogFilePath -Parent) -ChildPath ([IO.Path]::GetFileNameWithoutExtension($LogFilePath))
	# $appendix			= "_"
	# $LogFilePath			= "{0}{1}{2}{3}" -f
	# 	$baseLogName,
	# 	$appendix,
	# 	(Get-Date -Format yyyyMMdd_HHmmss),
	# 	$([IO.Path]::GetExtension($LogFilePath))
	
	Write-Host -ForegroundColor DarkYellow	-NoNewline	"Logging to: "
	Write-Host -ForegroundColor DarkCyan				"$LogFilePath"
	try {
		$null = Start-Transcript -Path $LogFilePath -Append 
	} catch {

	}

	#region Ensuring installation path
	if ([string]::IsNullOrEmpty($RootPath) -or
		-not $(Test-Path $RootPath)) {
		$RootPath = $PSScriptRoot
	}

	$modulesToInstall = Get-ChildItem -Path $RootPath -Directory | Where-Object {
		$(Test-Path (Join-Path $_.FullName "$($_.Name).psm1")) -and
		$(Test-Path (Join-Path $_.FullName "$($_.Name).psd1"))
	}

	if ([string]::IsNullOrEmpty($InstallPath) -or
		-not $(Test-Path $InstallPath -IsValid)) {
		# Default path for user modules
		$InstallationPaths = @(
			Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
		)
		$pwshExe = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
		if ($pwshExe -and $pwshExe.Version.Major -ge 6) {
			$InstallationPaths += (Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules")
		}
	} else {
		$env:PSModulePath	= $env:PSModulePath + [System.IO.Path]::PathSeparator + $InstallPath
		$InstallationPaths	= @( $InstallPath )
		$nonStandardPath	= $true
	}

	foreach ($InstallPath in $InstallationPaths) {
		if (-not (Test-Path -LiteralPath $InstallPath)) {
			$null = New-Item -Path $InstallPath -ItemType Directory
		}
	}
	#endregion

	#region Updating the modules
	foreach ($InstallPath in $InstallationPaths) {
		if (-not $Silent.IsPresent) {
			Write-Host -ForegroundColor DarkYellow -NoNewLine $("`nInstalling modules to: ")
			Write-Host -ForegroundColor DarkCyan				"$InstallPath"
		}
		$showOutroSuccess = $true
		foreach ($module in $modulesToInstall) {
			$sourceDirectory = Join-Path -Path $RootPath	-ChildPath $module
			$targetDirectory = Join-Path -Path $InstallPath	-ChildPath $module
			$success = Update-Directory -Source $sourceDirectory -Destination $targetDirectory
			if (-not $Silent.IsPresent) {
				if ($success) {
					Write-Host -ForegroundColor Magenta -NoNewLine	"  $module "
					Write-Host -ForegroundColor Green				"updated successfully"
				} else {
					$showOutroSuccess = $false
					Write-Host -ForegroundColor Red  -NoNewLine		"  Failed to update "
					Write-Host -ForegroundColor Magenta				"$module"
				}
			}
		}
	}
	#endregion

	if (-not $Silent.IsPresent) {
		if ($showOutroSuccess) {
			Show-HelpSuccess
			if ($nonStandardPath) {
				Show-HelpNonStandard -Paths $InstallationPaths
			}
		} else {
			Show-HelpFailure
		}
	}

	Write-Host ""
	# $env:PSModulePath = $oldPSModulePath

	$null = Stop-Transcript
}