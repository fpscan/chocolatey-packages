$ErrorActionPreference = 'Stop'

$packageName = 'retroarch-nightly'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64       = 'https://buildbot.libretro.com/nightly/windows/x86_64/RetroArch.7z'
$url32       = 'https://buildbot.libretro.com/nightly/windows/x86/RetroArch.7z'
$checksum64  = 'ACTUAL_CHECKSUM_64'
$checksum32  = 'ACTUAL_CHECKSUM_32'
$checksumType = 'sha256'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  url64bit      = $url64
  url           = $url32
  checksum64    = $checksum64
  checksum      = $checksum32
  checksumType64= $checksumType
  checksumType  = $checksumType
}

Install-ChocolateyZipPackage @packageArgs
