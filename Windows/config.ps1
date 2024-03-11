# Changing windows settings

  ## Set Dark mode
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type DWord -Force

  ## Set User Account Control to never notify
  New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0 -Type DWord -Force


# Configure Windows Terminal

  ## Set pwsh as default in Terminal
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -Type DWord -Force

  ## Set Windows Terminal as default terminal
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -Type DWord -Force

  ## Download and install Fira Code Nerd Font


  ## Set config for oh-my-posh


# Configure Taskbar

  ## Remove Search Bar
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0 -Type DWord -Force

  ## Show Widgets
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -Type DWord -Force

  ## Show Copilot in Taskbar
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -Type DWord -Force

# Configure Windows Explorer


