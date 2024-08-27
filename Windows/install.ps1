# Check for administrator privileges
$script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $script:isAdmin) {
    Write-Host "`n[WARNING] This script is not running with administrator privileges." -ForegroundColor DarkYellow
    Write-Host "Some installations may fail. Consider re-running as administrator for full functionality.`n" -ForegroundColor DarkYellow
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit
    }
}

# Default base URL for the package list
$defaultPackageListUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/packages.json"

# Function to prompt user for input
function Get-UserInput {
    param (
        [string]$prompt,
        [string]$default = ""
    )
    $response = Read-Host -Prompt "$prompt $(if ($default) { "[$default]" })"
    if ([string]::IsNullOrWhiteSpace($response)) { $response = $default }
    return $response
}

# Get user input
$extra = (Get-UserInput -prompt "Include extra packages? (y/n)" -default "n") -eq "y"
$source = Get-UserInput -prompt "Package manager to use (choco/winget/scoop)" -default "choco"
$categoriesInput = Get-UserInput -prompt "Enter categories to install (comma-separated, leave blank for all)"
$customPackageList = Get-UserInput -prompt "Custom package list URL or file path (leave blank for default)"
$forceSource = (Get-UserInput -prompt "Force use of primary source only? (y/n)" -default "n") -eq "y"

# Determine the package list path
if ($customPackageList) {
    if ([System.Uri]::IsWellFormedUriString($customPackageList, [System.UriKind]::Absolute)) {
        # It's a URL, download the file
        $packageListPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "package-manager", "custom-package-list.json")
        Invoke-WebRequest -Uri $customPackageList -OutFile $packageListPath
    } elseif (Test-Path $customPackageList) {
        # It's a local file path
        $packageListPath = $customPackageList
    } else {
        Write-Host "Error: The specified package list file does not exist."
        exit 1
    }
} else {
    # Use the default package list
    $packageListPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "package-manager", "package-list.json")
    Invoke-WebRequest -Uri $defaultPackageListUrl -OutFile $packageListPath
}

# Ensure the directory exists
$packageListDir = [System.IO.Path]::GetDirectoryName($packageListPath)
if (-not (Test-Path $packageListDir)) {
    New-Item -ItemType Directory -Path $packageListDir | Out-Null
}

# Load the JSON package list
$packageList = Get-Content $packageListPath | ConvertFrom-Json

# Process categories
if ([string]::IsNullOrWhiteSpace($categoriesInput)) {
    $categories = $packageList.categories | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    Write-Host "No categories specified. Installing all available categories."
} else {
    $categories = $categoriesInput -split ',' | ForEach-Object { $_.Trim() }
}

# Function to ensure package manager is installed
function Ensure-PackageManager {
    param (
        [string]$manager
    )
    switch ($manager) {
        "choco" {
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                if ($script:isAdmin) {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                } else {
                    Write-Host "Chocolatey is not installed and requires admin privileges to install. Please install Chocolatey manually." -ForegroundColor Yellow
                    exit 1
                }
            }

            # Enable global confirmation for Chocolatey
            choco feature enable -n allowGlobalConfirmation
        }
        "winget" {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Host "Winget is not installed. Please install it manually from the Microsoft Store or via Windows Update." -ForegroundColor Yellow
                exit 1
            }
        }
        "scoop" {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            }
        }
    }
}


# Function to install a single package
function Install-SinglePackage {
    param (
        [string]$manager,
        [string]$packageId,
        [bool]$userInstall
    )
    $userFlag = if ($userInstall) {
        switch ($manager) {
            "choco" { "--user" }
            "winget" { "--user" }
            "scoop" { "" }  # Scoop always installs for the current user
            default { "" }
        }
    } else { "" }

    switch ($manager) {
        "choco" { 
            if ($script:isAdmin -or -not $userInstall) {
                choco install -y $packageId $userFlag
            } else {
                Write-Host "Skipping ${packageId}: Chocolatey requires admin privileges for system-wide installations." -ForegroundColor Yellow
            }
        }
        "winget" { winget install -e --id $packageId $userFlag }
        "scoop" { scoop install $packageId }
    }
}

# Function to download installer
function Download-Installer {
    param (
        [string]$url,
        [string]$fileName
    )
    $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    $installerPath = Join-Path $downloadsPath "Installers"
    if (-not (Test-Path $installerPath)) {
        New-Item -ItemType Directory -Path $installerPath | Out-Null
    }
    $filePath = Join-Path $installerPath $fileName
    Invoke-WebRequest -Uri $url -OutFile $filePath
    Write-Host "Downloaded installer to: $filePath"
}

# Function to install packages
function Install-Packages {
    param (
        [string]$primaryManager,
        [array]$packages
    )
    $managers = @("choco", "winget", "scoop")

    foreach ($package in $packages) {
        $installed = $false
        $userInstall = $package.userInstall -eq $true

        # Try to install with the primary manager first
        if ($package.$primaryManager) {
            Write-Host "Installing $($package.name) using $primaryManager"
            Install-SinglePackage -manager $primaryManager -packageId $package.$primaryManager -userInstall $userInstall
            $installed = $true
        }

        # If not installed and fallback is allowed, try other managers
        if (-not $installed -and -not $forceSource) {
            foreach ($manager in $managers) {
                if ($manager -ne $primaryManager -and $package.$manager) {
                    Write-Host "Fallback: Installing $($package.name) using $manager"
                    Install-SinglePackage -manager $manager -packageId $package.$manager -userInstall $userInstall
                    $installed = $true
                    break
                }
            }
        }

        # If still not installed, check for direct download URL
        if (-not $installed -and $package.directDownload) {
            Write-Host "Package $($package.name) not available in package managers. Preparing for manual installation."
            Download-Installer -url $package.directDownload -fileName "$($package.name)_installer$([System.IO.Path]::GetExtension($package.directDownload))"
            $installed = $true
        }

        if (-not $installed) {
            Write-Host "Warning: Unable to install or prepare $($package.name). Not available in specified source(s) and no direct download link provided."
        }
    }
}

# Ensure the selected package manager is installed
Ensure-PackageManager $source

# Install packages for specified categories
foreach ($category in $categories) {
    $categoryPackages = $packageList.categories.$category | Where-Object {
        $extra -or (-not $_.extra)
    }
    if ($categoryPackages) {
        Write-Host "Installing packages for category: $category"
        Install-Packages -primaryManager $source -packages $categoryPackages
    } else {
        Write-Host "No packages found for category: $category"
    }
}

Write-Host "Installation complete! Install remaining packages manually from '~/Downloads/Installers'"
