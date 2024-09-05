# Function to check if running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Function to install Winget
function Install-Winget {
    Write-Host "Installing Winget..."
    $progressPreference = 'silentlyContinue'
    $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
    $latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
    Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile $latestWingetMsixBundle
    Add-AppxPackage -Path $latestWingetMsixBundle
    Remove-Item $latestWingetMsixBundle
}

# Function to install Chocolatey
function Install-Chocolatey {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Prompt for JSON file location
$jsonUrl = Read-Host "Enter the URL or local path to the packages.json file (press Enter for default)"
if ([string]::IsNullOrWhiteSpace($jsonUrl)) {
    $jsonUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/packages.json"
}

# Download or read the JSON file
try {
    if ($jsonUrl -like "http*") {
        $jsonContent = Invoke-WebRequest -Uri $jsonUrl | ConvertFrom-Json
    } else {
        $jsonContent = Get-Content $jsonUrl -Raw | ConvertFrom-Json
    }
} catch {
    Write-Host "Error: Unable to read or download the JSON file. Please check the URL or file path and try again."
    exit
}

# Prompt for package manager
$packageManager = Read-Host "Choose a package manager (winget/choco/direct)"

# Check if the chosen package manager is available and the shell has the correct elevation
$isAdmin = Test-Admin
if ($packageManager -eq "winget" -and $isAdmin) {
    Write-Host "Error: Winget should not be run in an elevated shell. Please run the script in a non-elevated PowerShell window."
    exit
} elseif ($packageManager -eq "choco" -and -not $isAdmin) {
    Write-Host "Error: Chocolatey requires an elevated shell. Please run the script as an administrator."
    exit
}

# Check if the chosen package manager is installed, and install if not
if ($packageManager -eq "winget") {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Install-Winget
    }
} elseif ($packageManager -eq "choco") {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Install-Chocolatey
    }
} elseif ($packageManager -eq "direct") {
    # No specific check needed for direct downloads
} else {
    Write-Host "Error: Invalid package manager selected. Please choose 'winget', 'choco', or 'direct'."
    exit
}

# Prompt for installing extra packages
$installExtra = Read-Host "Do you want to install extra marked packages? (y/n)"
$installExtra = $installExtra.ToLower() -eq 'y'

# Create Installer folder in Downloads if it doesn't exist
$installerFolder = Join-Path $env:USERPROFILE "Downloads\Installer"
if (-not (Test-Path $installerFolder)) {
    New-Item -ItemType Directory -Path $installerFolder | Out-Null
}

# Install packages
foreach ($category in $jsonContent.categories.PSObject.Properties) {
    Write-Host "Installing packages from category: $($category.Name)"
    foreach ($package in $category.Value) {
        $shouldInstall = -not $package.extra -or ($package.extra -and $installExtra)
        if ($shouldInstall) {
            if ($packageManager -eq "winget" -and $package.winget) {
                Write-Host "Installing $($package.name) using winget..."
                winget install --id $package.winget
            } elseif ($packageManager -eq "choco" -and $package.choco) {
                Write-Host "Installing $($package.name) using Chocolatey..."
                choco install $package.choco -y
            } elseif ($packageManager -eq "direct" -and $package.directDownload) {
                $fileName = Split-Path $package.directDownload -Leaf
                $filePath = Join-Path $installerFolder $fileName
                Write-Host "Downloading $($package.name) from $($package.directDownload)..."
                Invoke-WebRequest -Uri $package.directDownload -OutFile $filePath
                Write-Host "Installing $($package.name)..."
                Start-Process -FilePath $filePath -Wait
            }
        }
    }
}

Write-Host "Package installation complete."