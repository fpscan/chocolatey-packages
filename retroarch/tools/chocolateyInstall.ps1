$ErrorActionPreference = 'Stop'

$packageName   = 'retroarch'
$url           = 'https://buildbot.libretro.com/stable/1.22.2/windows/x86/RetroArch.7z'
$url64         = 'https://buildbot.libretro.com/stable/1.22.2/windows/x86_64/RetroArch.7z'
$checksum      = 'F25FEA07465E76D80250BDA69F108DAB88A876CF1191AAC208567032FB7F4185'
$checksum64    = 'B2139B1D0F9D4526DC6B5CE23CBB3EFDC766096FA6F2C3DF016818B486AC6372'
$checksumType  = 'sha256'
$checksumType64= 'sha256'

# Get the package parameters and back them up for the uninstaller (choco#1479)
$pp = Get-PackageParameters
$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$paramsFile = Join-Path (Split-Path -Parent $toolsPath) 'PackageParameters.xml'
try {
  Write-Debug "Writing package parameters to $paramsFile"
  Export-Clixml -Path $paramsFile -InputObject $pp -ErrorAction SilentlyContinue
} catch {
  Write-Debug "Could not cache package parameters: $_"
}

$is64bit = (Get-OSArchitectureWidth 2>$null) -eq 64 -or [System.Environment]::Is64BitOperatingSystem
if ($env:ChocolateyForceX86 -eq 'true' -or -not $is64bit) {
  $specificFolder = 'RetroArch-Win32'
} else {
  $specificFolder = 'RetroArch-Win64'
}

$baseDir = if ($pp.InstallDir) { $pp.InstallDir } elseif ($pp.InstallationPath) { $pp.InstallationPath } else { Get-ToolsLocation }
$appDir = Join-Path $baseDir $specificFolder
Write-Host "RetroArch is going to be installed in '$appDir'"

Install-ChocolateyZipPackage "$packageName" `
  -Url "$url" -Checksum "$checksum" -ChecksumType $checksumType `
  -Url64 "$url64" -Checksum64 "$checksum64" -ChecksumType64 $checksumType64 `
  -UnzipLocation "$baseDir" -SpecificFolder "$specificFolder"

# Create .gui files to ensure shimgen generates non-console shims
New-Item (Join-Path $appDir 'retroarch.exe.gui') -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
if (Test-Path (Join-Path $appDir 'retroarch_debug.exe')) {
  New-Item (Join-Path $appDir 'retroarch_debug.exe.gui') -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
}

# Register command-line shims with -UseStart for GUI execution
Install-BinFile -Name 'retroarch' -Path (Join-Path $appDir 'retroarch.exe') -UseStart
if (Test-Path (Join-Path $appDir 'retroarch_debug.exe')) {
  Install-BinFile -Name 'retroarch_debug' -Path (Join-Path $appDir 'retroarch_debug.exe') -UseStart
}

# Create Start Menu shortcut by default (unless opted out via /NoStartMenuShortcut)
if (-not $pp.NoStartMenuShortcut) {
  $startMenu = [System.Environment]::GetFolderPath('CommonPrograms')
  if (-not $startMenu) { $startMenu = [System.Environment]::GetFolderPath('Programs') }
  $startShortcut = Join-Path $startMenu 'RetroArch.lnk'
  $targetExe = Join-Path $appDir 'retroarch.exe'
  Install-ChocolateyShortcut -ShortcutFilePath $startShortcut `
    -TargetPath $targetExe -WorkingDirectory $appDir `
    -WindowStyle 3
}

if ($pp.DesktopShortcut) {
  $desktop = [System.Environment]::GetFolderPath('Desktop')
  $shortcutPath = Join-Path $desktop 'RetroArch.lnk'
  $targetExe = Join-Path $appDir 'retroarch.exe'
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutPath `
    -TargetPath $targetExe -WorkingDirectory $appDir `
    -WindowStyle 3
}
