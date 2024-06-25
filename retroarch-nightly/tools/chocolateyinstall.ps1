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

  checksum      = Get-RemoteChecksum $url32
  checksumType  = 'sha256'
  checksum64    = Get-RemoteChecksum $url64
  checksumType64= 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
