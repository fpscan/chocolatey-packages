[CmdletBinding()]
param(
  [string]$Version = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$packageDir = $PSScriptRoot
$nuspecPath = Join-Path $packageDir "retroarch-nightly.nuspec"
$installScriptPath = Join-Path $packageDir "tools\chocolateyinstall.ps1"

$url32 = "https://buildbot.libretro.com/nightly/windows/x86/RetroArch.7z"
$url64 = "https://buildbot.libretro.com/nightly/windows/x86_64/RetroArch.7z"

function Get-UrlSha256([string]$url) {
  $tempFile = [System.IO.Path]::GetTempFileName()
  try {
    Write-Host "Downloading $url to compute SHA256..."
    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
    return (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLower()
  } finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
  }
}

$hash32 = Get-UrlSha256 $url32
$hash64 = Get-UrlSha256 $url64

Write-Host "SHA256 (32-bit): $hash32"
Write-Host "SHA256 (64-bit): $hash64"

# Read current checksums and version from chocolateyinstall.ps1
$installContent = Get-Content $installScriptPath -Raw
$currentHash32 = ""
$currentHash64 = ""

if ($installContent -match "(?m)^\$checksum\s*=\s*'([a-fA-F0-9]+)'") {
  $currentHash32 = $matches[1].ToLower()
}
if ($installContent -match "(?m)^\$checksum64\s*=\s*'([a-fA-F0-9]+)'") {
  $currentHash64 = $matches[1].ToLower()
}

[xml]$nuspecXml = Get-Content $nuspecPath
$currentVersion = $nuspecXml.package.metadata.version

if (-not $Version) {
  $Version = (Get-Date -Format "yyyy.MM.dd")
}

$checksumsUnchanged = ($currentHash32 -eq $hash32 -and $currentHash64 -eq $hash64)
if ($checksumsUnchanged -and -not $Force) {
  Write-Host "Nightly checksums have not changed since last build ($currentVersion). Skipping update."
  return @{
    Updated = $false
    Version = $currentVersion
    Checksum32 = $hash32
    Checksum64 = $hash64
  }
}

Write-Host "Updating retroarch-nightly to version $Version..."

# Update chocolateyinstall.ps1
$installContent = [regex]::Replace($installContent, "(?m)^\$url\s*=.*", "`$url           = '$url32'")
$installContent = [regex]::Replace($installContent, "(?m)^\$url64\s*=.*", "`$url64         = '$url64'")
$installContent = [regex]::Replace($installContent, "(?m)^\$checksum\s*=.*", "`$checksum      = '$hash32'")
$installContent = [regex]::Replace($installContent, "(?m)^\$checksum64\s*=.*", "`$checksum64    = '$hash64'")
Set-Content -Path $installScriptPath -Value $installContent -Encoding UTF8

# Update retroarch-nightly.nuspec
$nuspecContent = Get-Content $nuspecPath -Raw
$nuspecContent = [regex]::Replace($nuspecContent, "(?m)<version>.*?</version>", "<version>$Version</version>")
Set-Content -Path $nuspecPath -Value $nuspecContent -Encoding UTF8

# Clean up PackageParameters.xml if generated
$paramsFile = Join-Path $packageDir "PackageParameters.xml"
if (Test-Path $paramsFile) {
  Remove-Item $paramsFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Successfully updated retroarch-nightly to $Version"
return @{
  Updated = $true
  Version = $Version
  Checksum32 = $hash32
  Checksum64 = $hash64
}
