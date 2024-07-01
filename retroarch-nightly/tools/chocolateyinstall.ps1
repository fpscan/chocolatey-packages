$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://buildbot.libretro.com/nightly/windows/x86_64/RetroArch.7z'
$url32 = 'https://buildbot.libretro.com/nightly/windows/x86/RetroArch.7z'
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = $url32
  url64bit      = $url64
  softwareName  = 'retroarch*'
  checksum      = 'bb4651d63aebdee95c3a3a5649af5fee069f357fd577d2bfce8f099524a72d88'
  checksumType  = 'sha256'
  checksum64    = 'fbf6e748b957cc25c64c5c7a6d6bece9fb56ee309253332846b39d61b0f64410'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs
