$ErrorActionPreference = 'Stop'
$packageName = 'retroarch-nightly'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# Remove the RetroArch folder
Remove-Item -Path "$toolsDir\RetroArch" -Recurse -Force