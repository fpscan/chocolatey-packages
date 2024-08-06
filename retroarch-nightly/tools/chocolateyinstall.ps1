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
  checksum      = 'ab6d617c0dd5a0f821fdb2ffe478e25869b8aaac0ece8e67c085b450e8d36077'
  checksumType  = 'sha256'
  checksum64    = 'b4dbc3447f7d65daf7f672776bc0b7b681b8406e64d5f366abfea48b9d579f7d'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs
