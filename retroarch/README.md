# RetroArch (Stable) Chocolatey Package

RetroArch is a frontend for libretro, an open API which exposes the functionality of a game, emulator or certain kinds of multimedia applications. RetroArch builds around the libretro API to provide a unified interface for libretro cores.

## Installation

```powershell
choco install retroarch
```

### Package Parameters

The following package parameters can be passed during installation:

* `/InstallDir:{path}` - Custom installation base directory (defaults to Chocolatey tools location, typically `C:\tools`). RetroArch installs into its subfolder (`RetroArch-Win64` or `RetroArch-Win32`).
* `/InstallationPath:{path}` - Alias for `/InstallDir`.
* `/DesktopShortcut` - Creates a desktop shortcut for RetroArch with the correct working directory.
* `/NoStartMenuShortcut` - Do not create a Start Menu entry (created by default).

#### Examples

Install with a desktop shortcut:
```powershell
choco install retroarch --params '"/DesktopShortcut"'
```

Install without creating a Start Menu shortcut:
```powershell
choco install retroarch --params '"/NoStartMenuShortcut"'
```

Install into a custom directory:
```powershell
choco install retroarch --params '"/InstallDir:D:\Emulators"'
```

Install with both custom directory and desktop shortcut:
```powershell
choco install retroarch --params '"/InstallDir:D:\Emulators /DesktopShortcut"'
```

## Features & Notes

* **GUI Shims**: Shims for `retroarch.exe` and `retroarch_debug.exe` are created with `-UseStart` and `.gui` flags, allowing you to launch RetroArch directly from PowerShell / CMD without keeping a background terminal console open.
* **Architecture Support**: Automatically detects 64-bit and 32-bit Windows, extracting the respective native build (`RetroArch-Win64` or `RetroArch-Win32`). Can be forced to 32-bit with `--forceX86`.
* **Clean Uninstallation**: Uninstallation cleanly removes registered shims, desktop shortcuts, and empty directories while safeguarding any user save files, savestates, or custom playlists.

