$ErrorActionPreference = 'Stop'

$packageName   = 'retroarch'
$zip32         = 'RetroArch.7z'
$zip64         = 'RetroArch.7z'

$is64bit = (Get-OSArchitectureWidth 2>$null) -eq 64 -or [System.Environment]::Is64BitOperatingSystem
if ($env:ChocolateyForceX86 -eq 'true' -or -not $is64bit) {
  $specificFolder = 'RetroArch-Win32'
  $zip = $zip32
} else {
  $specificFolder = 'RetroArch-Win64'
  $zip = $zip64
}

# Uninstall unzipped files tracked by Chocolatey
Uninstall-ChocolateyZipPackage -PackageName "$packageName" -ZipFileName "$zip"

# Retrieve package parameters (reading cached copy if available)
$pp = Get-PackageParameters
$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$paramsFile = Join-Path (Split-Path -Parent $toolsPath) 'PackageParameters.xml'
if ($null -eq $pp -or $pp.Count -eq 0) {
  if (Test-Path -Path $paramsFile) {
    Write-Debug "Loading package parameters from $paramsFile"
    try {
      $pp = Import-Clixml -Path $paramsFile -ErrorAction SilentlyContinue
    } catch {
      $pp = @{}
    }
  } else {
    $pp = @{}
  }
}

$baseDir = if ($pp.InstallDir) { $pp.InstallDir } elseif ($pp.InstallationPath) { $pp.InstallationPath } else { Get-ToolsLocation }
$appDir = Join-Path $baseDir $specificFolder

# Remove shims
Uninstall-BinFile -Name 'retroarch' -Path (Join-Path $appDir 'retroarch.exe')
if (Test-Path (Join-Path $appDir 'retroarch_debug.exe')) {
  Uninstall-BinFile -Name 'retroarch_debug' -Path (Join-Path $appDir 'retroarch_debug.exe')
}

# Remove desktop shortcut if created
if ($pp.DesktopShortcut) {
  $desktop = [System.Environment]::GetFolderPath('Desktop')
  $shortcutPath = Join-Path $desktop 'RetroArch.lnk'
  if (Test-Path $shortcutPath) {
    Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue | Out-Null
  }
}

# Clean up empty installation folder while preserving user saves/configs
if (Test-Path $appDir) {
  $isEmpty = @(Get-ChildItem -Path $appDir -Force).Count -eq 0
  if ($isEmpty) {
    Remove-Item -Path $appDir -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Removed empty installation directory: $appDir"
  } else {
    Write-Host "Installation directory is not empty (preserved user configurations or saves): $appDir"
  }
}

# Remove cached parameter file
if (Test-Path $paramsFile) {
  Remove-Item -Path $paramsFile -Force -ErrorAction SilentlyContinue
}
