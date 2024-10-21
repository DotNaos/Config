<h1>Config</h1>

<!-- TODO: -->

<!-- Fix user install in install script -->
<!-- In Configuration script, prompt the user for credentials like github name, email etc. and the files are then created. -->
<!-- Incorporate the common fixes into the config script.  -->
<!-- https://github.com/black7375/Breeze-Cursors-for-Windows Breeze Cursor in Config-->

## Windows
### Installation

> [!Warning]
> Run as Administrator

1. [Debloat Windows 11 Tool (Also available in config)](https://github.com/Raphire/Win11Debloat)
```pwsh
& ([scriptblock]::Create((irm "https://win11debloat.raphi.re/")))
```

2. Install packages 
```pwsh
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DotNaos/config/main/Windows/install.ps1" -UseBasicParsing).Content
```

### Configuration
1. Copy config files and configure
```pwsh
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DotNaos/config/main/Windows/configure.ps1" -UseBasicParsing).Content
```

> [!Warning]
> Here are fixes for common problems
- [Time not in sync after OS switch](https://answers.microsoft.com/en-us/windows/forum/all/automatic-windows-resync-time-after-reboot-setup/7a762b13-6a90-4731-9287-bdab328da78c) -> Enable Windows time Service to start automatically 
- Powershell always in Admin Mode -> Turn UAC back on

## Linux
> Common Problems
- [Add Windows to Grub Boot](https://youtu.be/xBPn0fF8bTY?si=NY1biG0l_pI7pWGs)

## ( MACOS )
( WIP )
