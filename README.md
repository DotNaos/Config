<h1>Config</h1>

## TODO
- [ ] Install Script
- [ ] Config Script for settings
- [ ] Add .env file or similar for credentials



<details>
<summary>Programm List </summary>

- [ ] Arc browser

### Scripts
- [ ] Vencord

</details>

## Install
---
### Windows

1. Install Chocolatey in Powershell as **Admin**, also deactivating the execution policy:
```powershell
Set-ExecutionPolicy Bypass -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

2. Install all the programs in [Packages config](Windows/packages/) with:
```powershell
 iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/install.ps1'))
```

Or if you have your own config url:
```powershell
 iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/custom_install.ps1'))
```


3. Use debloat Tools

- [Win11Debloat](https://github.com/Raphire/Win11Debloat)



3. Run the [Config Script](Windows/config.ps1) to set the settings
```powershell
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.ps1'))
```

Same for the custom config:
```powershell
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/custom_config.ps1'))
```

4. Common Problems
- [Time not in sync after OS switch](https://answers.microsoft.com/en-us/windows/forum/all/automatic-windows-resync-time-after-reboot-setup/7a762b13-6a90-4731-9287-bdab328da78c) -> Enable Windows time Service to start automatically 
 
### Linux
2. Common Problems
- [Add Windows to Grub Boot](https://youtu.be/xBPn0fF8bTY?si=NY1biG0l_pI7pWGs)

### ( MACOS )
( WIP )
