# Function to check if running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Function to refresh environment variables
function Update-SessionEnvironment {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Environment variables refreshed." -ForegroundColor Green
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
    Write-Host "Winget installation complete." -ForegroundColor Green
    Update-SessionEnvironment
}

# Function to install Chocolatey
function Install-Chocolatey {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installation complete." -ForegroundColor Green
    Update-SessionEnvironment
    # Import Chocolatey profile to use refreshenv
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
}

# Function to run Winget commands in a non-elevated context
function Invoke-WingetCommand {
    param (
        [string]$Command
    )
    $wingetPath = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
    if (-not $wingetPath) {
        Write-Host "Winget not found in PATH. Attempting to find it..." -ForegroundColor Yellow
        $wingetPath = "${env:ProgramFiles}\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
        $wingetPath = Resolve-Path $wingetPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1
    }
    if (-not $wingetPath) {
        Write-Host "Winget not found. Please ensure it's installed correctly." -ForegroundColor Red
        return
    }
    $scriptBlock = [Scriptblock]::Create("& '$wingetPath' $Command")
    
    if (Test-Admin) {
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $scriptBlock -Wait -WindowStyle Hidden
    } else {
        Invoke-Expression $scriptBlock
    }
}

# Function to exit script with a message and wait for user input
function Exit-WithMessage {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Prompt for JSON file location
$jsonUrl = Read-Host "Enter the URL or local path to the packages.json file (press Enter for default)"
if ([string]::IsNullOrWhiteSpace($jsonUrl)) {
    $jsonUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/packages.json"
}

# Download or read the JSON file
try {
    Write-Host "Fetching package information..." -ForegroundColor Cyan
    if ($jsonUrl -like "http*") {
        $jsonContent = Invoke-WebRequest -Uri $jsonUrl | ConvertFrom-Json
    } else {
        # Remove any surrounding quotes if present
        $jsonUrl = $jsonUrl.Trim('"')
        if (Test-Path $jsonUrl) {
            $jsonContent = Get-Content $jsonUrl -Raw | ConvertFrom-Json
        } else {
            throw "File not found: $jsonUrl"
        }
    }
    Write-Host "Package information retrieved successfully." -ForegroundColor Green
} catch {
    Exit-WithMessage "Error: Unable to read or download the JSON file. Please check the URL or file path and try again. Error details: $_"
}


# Prompt for package manager
$packageManager = Read-Host "Choose a package manager (winget/choco/direct)"

$isAdmin = Test-Admin

# Check if the chosen package manager is available and install if necessary
if ($packageManager -eq "winget") {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        if ($isAdmin) {
            Install-Winget
        } else {
            Exit-WithMessage "Winget is not installed and requires elevation to install. Please run the script as an administrator to install Winget."
        }
    } else {
        Write-Host "Winget is already installed." -ForegroundColor Green
    }
} elseif ($packageManager -eq "choco") {
    if (-not $isAdmin) {
        Exit-WithMessage "Error: Chocolatey requires an elevated shell. Please run the script as an administrator."
    }
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Install-Chocolatey
    } else {
        Write-Host "Chocolatey is already installed." -ForegroundColor Green
        # Ensure Chocolatey profile is imported for existing installation
        $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        refreshenv
    }
} elseif ($packageManager -eq "direct") {
    Write-Host "Using direct downloads." -ForegroundColor Green
} else {
    Exit-WithMessage "Error: Invalid package manager selected. Please choose 'winget', 'choco', or 'direct'."
}

# Prompt for installing extra packages
$installExtra = Read-Host "Do you want to install extra marked packages? (y/n)"
$installExtra = $installExtra.ToLower() -eq 'y'

# Prompt for category installation preference
$categoryPreference = Read-Host "How do you want to install categories? (0 - All categories, 1 - Ask for each category) [Default: 0]"
if ([string]::IsNullOrWhiteSpace($categoryPreference)) {
    $categoryPreference = "0"
}

# Create Installer folder in Downloads if it doesn't exist
$installerFolder = Join-Path $env:USERPROFILE "Downloads\Installer"
if (-not (Test-Path $installerFolder)) {
    New-Item -ItemType Directory -Path $installerFolder | Out-Null
    Write-Host "Created Installer folder: $installerFolder" -ForegroundColor Green
}

# Install packages
foreach ($category in $jsonContent.categories.PSObject.Properties) {
    $installCategory = $true
    if ($categoryPreference -eq "1") {
        $response = Read-Host "Do you want to install packages from the category '$($category.Name)'? (Y/n) [Default: Y]"
        $installCategory = [string]::IsNullOrWhiteSpace($response) -or $response.ToLower() -eq 'y'
    }

    if ($installCategory) {
        Write-Host "Installing packages from category: $($category.Name)" -ForegroundColor Cyan
        foreach ($package in $category.Value) {
            $shouldInstall = -not $package.extra -or ($package.extra -and $installExtra)
            if ($shouldInstall) {
                if ($packageManager -eq "winget" -and $package.winget) {
                    Write-Host "Installing $($package.name) using winget..." -ForegroundColor Yellow
                    Invoke-WingetCommand "install --id $($package.winget)"
                } elseif ($packageManager -eq "choco" -and $package.choco) {
                    Write-Host "Installing $($package.name) using Chocolatey..." -ForegroundColor Yellow
                    choco install $package.choco -y
                } elseif ($packageManager -eq "direct" -and $package.directDownload) {
                    $fileName = Split-Path $package.directDownload -Leaf
                    $filePath = Join-Path $installerFolder $fileName
                    Write-Host "Downloading $($package.name) from $($package.directDownload)..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri $package.directDownload -OutFile $filePath
                    Write-Host "Installing $($package.name)..." -ForegroundColor Yellow
                    Start-Process -FilePath $filePath -Wait
                }
                Write-Host "Finished installing $($package.name)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Skipping category: $($category.Name)" -ForegroundColor Gray
    }
}

Write-Host "Package installation complete." -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")