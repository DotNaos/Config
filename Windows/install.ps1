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
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
        }
        "winget" {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Host "Winget is not installed. Attempting to install..."

                # Get latest download url
                $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
                    Select-Object -ExpandProperty "assets" |
                    Where-Object "browser_download_url" -Match '.msixbundle' |
                    Select-Object -ExpandProperty "browser_download_url"

                # Download
                $setupPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "WingetSetup.msix")
                Invoke-WebRequest -Uri $URL -OutFile $setupPath -UseBasicParsing

                # Install
                try {
                    Add-AppxPackage -Path $setupPath
                    Write-Host "Winget installed successfully."
                }
                catch {
                    Write-Host "Failed to install Winget. Error: $_"
                    exit 1
                }
                finally {
                    # Clean up
                    Remove-Item $setupPath -ErrorAction SilentlyContinue
                }

                # Verify installation
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    Write-Host "Winget installation failed. Please install it manually from the Microsoft Store."
                    exit 1
                }
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
        [string]$packageId
    )
    switch ($manager) {
        "choco" { choco install -y $packageId }
        "winget" { winget install -e --id $packageId }
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

        # Try to install with the primary manager first
        if ($package.$primaryManager) {
            Write-Host "Installing $($package.name) using $primaryManager"
            Install-SinglePackage -manager $primaryManager -packageId $package.$primaryManager
            $installed = $true
        }

        # If not installed and fallback is allowed, try other managers
        if (-not $installed -and -not $forceSource) {
            foreach ($manager in $managers) {
                if ($manager -ne $primaryManager -and $package.$manager) {
                    Write-Host "Fallback: Installing $($package.name) using $manager"
                    Install-SinglePackage -manager $manager -packageId $package.$manager
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

Write-Host "Installation complete!"
