<h1>Config</h1>

## TODO
- [ ] Install Script
- [ ] Config Script for settings
- [ ] Add .env file or similar for credentials



<details>
<summary>Programm List </summary>

- [ ] Arc browser

### Scripts
- [ ] SpotX
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
- [Win-Debloat-Tools](https://github.com/LeDragoX/Win-Debloat-Tools)
- [Win11Debloat](https://github.com/Raphire/Win11Debloat)



3. Run the [Config Script](Windows/config.ps1) to set the settings
```powershell
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.ps1'))
```

Same for the custom config:
```powershell
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/custom_config.ps1'))
``` 

### Linux
( WIP )

### ( MACOS )
( WIP )
