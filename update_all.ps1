[CmdletBinding()]
param(
  [switch]$Force,
  [switch]$Push
)

$ErrorActionPreference = 'Stop'
$packages = @('retroarch', 'retroarch-nightly')

foreach ($pkg in $packages) {
  $pkgDir = Join-Path $PSScriptRoot $pkg
  $updateScript = Join-Path $pkgDir 'update.ps1'

  if (-not (Test-Path $updateScript)) {
    Write-Warning "No update.ps1 found for $pkg, skipping."
    continue
  }

  Write-Host "`n=== Checking for updates: $pkg ===" -ForegroundColor Cyan
  try {
    Push-Location $pkgDir
    $params = @{}
    if ($Force) { $params['Force'] = $true }
    $result = & $updateScript @params

    if ($Push -and ($result.Updated -or $Force)) {
      $ver = $result.Version
      if (-not $ver) {
        [xml]$nuspec = Get-Content (Join-Path $pkgDir "$pkg.nuspec")
        $ver = $nuspec.package.metadata.version
      }
      Write-Host "Packing $pkg $ver..." -ForegroundColor Green
      choco pack
      $nupkg = Join-Path $pkgDir "$pkg.$ver.nupkg"
      if (Test-Path $nupkg) {
        Write-Host "Pushing $nupkg to Chocolatey..." -ForegroundColor Green
        choco push $nupkg --source https://push.chocolatey.org/
      }
    }
  } catch {
    Write-Error "Error updating $pkg: $_"
  } finally {
    Pop-Location
  }
}
