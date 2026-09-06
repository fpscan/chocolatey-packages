[CmdletBinding()]
param(
  [string]$Version = '',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$packageDir = $PSScriptRoot
$nuspecPath = Join-Path $packageDir 'retroarch.nuspec'
$installScriptPath = Join-Path $packageDir 'tools\chocolateyInstall.ps1'

function Get-LatestStableVersion {
  try {
    $headers = @{ 'User-Agent' = 'Chocolatey-RetroArch-Updater' }
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/libretro/RetroArch/releases/latest' -Headers $headers -UseBasicParsing
    if ($release -and $release.tag_name) {
      return ($release.tag_name -replace '^v', '')
    }
  } catch {
    Write-Warning "Could not fetch latest release from GitHub API: $_"
  }
  return $null
}

function Get-UrlSha256([string]$url) {
  $tempFile = [System.IO.Path]::GetTempFileName()
  try {
    Write-Host "Downloading $url to compute SHA256..."
    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
    return (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToUpper()
  } finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
  }
}

if (-not $Version) {
  $Version = Get-LatestStableVersion
}

if (-not $Version) {
  Write-Error "Unable to determine latest stable version. Please specify -Version parameter."
  return
}

# Read current version from nuspec
[xml]$nuspecXml = Get-Content $nuspecPath
$currentVersion = $nuspecXml.package.metadata.version

Write-Host "Current package version: $currentVersion"
Write-Host "Target version: $Version"

if ($currentVersion -eq $Version -and -not $Force) {
  Write-Host "Package is already at version $Version. Use -Force to update anyway."
  return
}

$url32 = "https://buildbot.libretro.com/stable/$Version/windows/x86/RetroArch.7z"
$url64 = "https://buildbot.libretro.com/stable/$Version/windows/x86_64/RetroArch.7z"

$hash32 = Get-UrlSha256 $url32
$hash64 = Get-UrlSha256 $url64

Write-Host "SHA256 (32-bit): $hash32"
Write-Host "SHA256 (64-bit): $hash64"

# Update chocolateyInstall.ps1
$installContent = Get-Content $installScriptPath -Raw
$installContent = [regex]::Replace($installContent, "(?m)^\$url\s*=.*", "`$url           = '$url32'")
$installContent = [regex]::Replace($installContent, "(?m)^\$url64\s*=.*", "`$url64         = '$url64'")
$installContent = [regex]::Replace($installContent, "(?m)^\$checksum\s*=.*", "`$checksum      = '$hash32'")
$installContent = [regex]::Replace($installContent, "(?m)^\$checksum64\s*=.*", "`$checksum64    = '$hash64'")
Set-Content -Path $installScriptPath -Value $installContent -Encoding UTF8

# Update retroarch.nuspec
$nuspecContent = Get-Content $nuspecPath -Raw
$nuspecContent = [regex]::Replace($nuspecContent, "(?m)<version>.*?</version>", "<version>$Version</version>")
$nuspecContent = [regex]::Replace($nuspecContent, "(?m)<releaseNotes>.*?</releaseNotes>", "<releaseNotes>https://github.com/libretro/RetroArch/releases/tag/v$Version</releaseNotes>")
Set-Content -Path $nuspecPath -Value $nuspecContent -Encoding UTF8

# Clean up PackageParameters.xml if generated
$paramsFile = Join-Path $packageDir 'PackageParameters.xml'
if (Test-Path $paramsFile) {
  Remove-Item $paramsFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Successfully updated retroarch to $Version"
