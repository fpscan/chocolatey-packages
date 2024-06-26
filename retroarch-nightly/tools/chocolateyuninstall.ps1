$ErrorActionPreference = 'Stop'
$packageName   = 'retroarch-nightly'
$zip32         = 'RetroArch.7z'
$zip64         = 'RetroArch.7z'

if ((Get-ProcessorBits 32) -or $env:ChocolateyForceX86 -eq 'true') {
  $specificFolder = "RetroArch-Win32"
  $zip = $zip32
} else {
  $specificFolder = "RetroArch-Win64"
  $zip = $zip64
}

Uninstall-ChocolateyZipPackage "$packageName" "$zip"

# Get package parameters
$pp = Get-PackageParameters
if ($null -eq $pp -or $pp.Count -eq 0) {
  # Work around for choco#1479 https://github.com/chocolatey/choco/issues/1479
  $toolsPath = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
  $paramsFile = Join-Path (Split-Path -Parent $toolsPath) 'PackageParameters.xml'
  if (Test-Path -Path $paramsFile) {
    Write-Debug "Loading package parameters from $paramsFile"
    $pp = Import-Clixml -Path $paramsFile
  } else {
    Write-Debug "No package parameters available; shims and desktop shortcut won't be removed if they were created"
    $pp = @{}
  }
}

$installDir = Join-Path $(Get-ToolsLocation) $specificFolder
if ($pp.InstallDir -or $pp.InstallationPath ) { $installDir = $pp.InstallDir + $pp.InstallationPath }

if ($installDir -ne $toolsPath) {
  Uninstall-BinFile retroarch -path "$installDir\retroarch.exe"
  if (Test-Path "$installDir\retroarch_debug.exe") {
    Uninstall-BinFile retroarch_debug -path "$installDir\retroarch_debug.exe"
  }
}

if ($pp.DesktopShortcut) {
  $desktop = [System.Environment]::GetFolderPath("Desktop")
  Remove-Item "$desktop\RetroArch Nightly.lnk" -ErrorAction SilentlyContinue -Force | Out-Null
}

# Clean up the installation directory if it's empty
if (Test-Path $installDir) {
  $isEmpty = @(Get-ChildItem -Path $installDir -Force).Count -eq 0
  if ($isEmpty) {
    Remove-Item -Path $installDir -Force -Recurse
    Write-Host "Removed empty installation directory: $installDir"
  } else {
    Write-Host "Installation directory is not empty. Manual cleanup may be required: $installDir"
  }
}

# Remove the package parameters file
if (Test-Path $paramsFile) {
  Remove-Item -Path $paramsFile -Force
  Write-Debug "Removed package parameters file: $paramsFile"
}
