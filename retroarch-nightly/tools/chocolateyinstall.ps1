$ErrorActionPreference = 'Stop'

$packageName   = 'retroarch-nightly'
$url           = 'https://buildbot.libretro.com/nightly/windows/x86/RetroArch.7z'
$url64         = 'https://buildbot.libretro.com/nightly/windows/x86_64/RetroArch.7z'
$checksum      = 'ab6d617c0dd5a0f821fdb2ffe478e25869b8aaac0ece8e67c085b450e8d36077'
$checksum64    = 'b4dbc3447f7d65daf7f672776bc0b7b681b8406e64d5f366abfea48b9d579f7d'
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
Write-Host "RetroArch Nightly is going to be installed in '$appDir'"

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
Install-BinFile -Name 'retroarch-nightly' -Path (Join-Path $appDir 'retroarch.exe') -UseStart
Install-BinFile -Name 'retroarch' -Path (Join-Path $appDir 'retroarch.exe') -UseStart
if (Test-Path (Join-Path $appDir 'retroarch_debug.exe')) {
  Install-BinFile -Name 'retroarch-nightly_debug' -Path (Join-Path $appDir 'retroarch_debug.exe') -UseStart
  Install-BinFile -Name 'retroarch_debug' -Path (Join-Path $appDir 'retroarch_debug.exe') -UseStart
}

# Create Start Menu shortcut by default (unless opted out via /NoStartMenuShortcut)
if (-not $pp.NoStartMenuShortcut) {
  $startMenu = [System.Environment]::GetFolderPath('CommonPrograms')
  if (-not $startMenu) { $startMenu = [System.Environment]::GetFolderPath('Programs') }
  $startShortcut = Join-Path $startMenu 'RetroArch Nightly.lnk'
  $targetExe = Join-Path $appDir 'retroarch.exe'
  Install-ChocolateyShortcut -ShortcutFilePath $startShortcut `
    -TargetPath $targetExe -WorkingDirectory $appDir `
    -WindowStyle 3
}

if ($pp.DesktopShortcut) {
  $desktop = [System.Environment]::GetFolderPath('Desktop')
  $shortcutPath = Join-Path $desktop 'RetroArch Nightly.lnk'
  $targetExe = Join-Path $appDir 'retroarch.exe'
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutPath `
    -TargetPath $targetExe -WorkingDirectory $appDir `
    -WindowStyle 3
}
