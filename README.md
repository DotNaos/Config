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

1. Install Chocolatey in Powershell as **Admin:**
```powershell
Set-ExecutionPolicy Bypass -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

2. Install all the programs in [Packages config](Windows/packages/) with:
```powershell
 iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/install.ps1'))
```

3. Run the [Config Script](Windows/config.ps1) to set the settings
```powershell
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.ps1'))
```

### Linux
( WIP )

### ( MACOS )
( WIP )
