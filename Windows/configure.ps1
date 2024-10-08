# Function to download a file from a URL
function Download-File($url, $outputPath) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "Successfully downloaded: $url to $outputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error downloading $url : $_" -ForegroundColor Red
    }
}

# Function to clone a GitHub repository
function Clone-Repository($url, $outputPath) {
    try {
        git clone $url $outputPath 2>&1 | Out-Null
        Write-Host "Successfully cloned repository: $url to $outputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error cloning repository $url : $_" -ForegroundColor Red
    }
}

# Function to expand environment variables in a path
function Expand-EnvPath($path) {
    return [System.Environment]::ExpandEnvironmentVariables($path)
}

# Function to execute commands
function Execute-Commands($commands) {
    foreach ($command in $commands) {
        $expandedCommand = Expand-EnvPath $command
        Write-Host "Executing command: $expandedCommand" -ForegroundColor Cyan
        try {
            Invoke-Expression $expandedCommand
            Write-Host "Command executed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Error executing command: $_" -ForegroundColor Red
        }
    }
}

# Function to debloat Windows
function Debloat-Windows($config) {
    Write-Host "Debloating Windows..." -ForegroundColor Yellow
    
    foreach ($app in $config.appsToRemove) {
        Write-Host "Removing $app" -ForegroundColor Cyan
        Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    }

    if ($config.removePinnedApps) {
        Write-Host "Removing pinned apps from Start Menu and Taskbar" -ForegroundColor Cyan
        $startLayoutPath = "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"
        Set-Content -Path $startLayoutPath -Value '<?xml version="1.0" encoding="utf-8"?><LayoutModificationTemplate xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" />'
        
        # Remove pinned apps from taskbar (Windows 11)
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
        if (Test-Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
        }
    }

    Write-Host "Windows debloating complete" -ForegroundColor Green
}

# Function to configure Windows settings
function Configure-WindowsSettings($settings) {
    Write-Host "Configuring Windows settings..." -ForegroundColor Yellow

    foreach ($setting in $settings) {
        Write-Host "Configuring $($setting.name)" -ForegroundColor Cyan
        Set-ItemProperty -Path $setting.path -Name $setting.name -Value $setting.value
    }

    Write-Host "Windows settings configuration complete" -ForegroundColor Green
}

# Function to enable optional features
function Enable-OptionalFeatures($features) {
    Write-Host "Enabling optional features..." -ForegroundColor Yellow

    foreach ($feature in $features) {
        Write-Host "Enabling $feature" -ForegroundColor Cyan
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All
    }

    Write-Host "Optional features enabled" -ForegroundColor Green
}

# Main script execution starts here

# Prompt for JSON file location
$jsonUrl = Read-Host "Enter the URL or local path to the config.json file (press Enter for default)"
if ([string]::IsNullOrWhiteSpace($jsonUrl)) {
    $jsonUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"
}

# Download or read the JSON file
try {
    Write-Host "Fetching config information..." -ForegroundColor Cyan
    if ($jsonUrl -like "http*") {
        $config = Invoke-WebRequest -Uri $jsonUrl | ConvertFrom-Json
    } else {
        # Remove any surrounding quotes if present
        $jsonUrl = $jsonUrl.Trim('"')
        if (Test-Path $jsonUrl) {
            $config = Get-Content $jsonUrl -Raw | ConvertFrom-Json
        } else {
            throw "File not found: $jsonUrl"
        }
    }
    Write-Host "Config information retrieved successfully." -ForegroundColor Green
} catch {
    Exit-WithMessage "Error: Unable to read or download the JSON file. Please check the URL or file path and try again. Error details: $_"
}

# Debloat Windows
if ($config.debloat) {
    Debloat-Windows $config.debloat
}

# Configure Windows settings
if ($config.windowsSettings) {
    Configure-WindowsSettings $config.windowsSettings
}

# Enable optional features
if ($config.optionalFeatures) {
    Enable-OptionalFeatures $config.optionalFeatures
}

# Process each configuration item
foreach ($item in $config.configs) {
    Write-Host "`nProcessing configuration: $($item.name)" -ForegroundColor Yellow
    
    # Execute pre-commands if present
    if ($item.preCommands) {
        Write-Host "Executing pre-commands for $($item.name)" -ForegroundColor Cyan
        Execute-Commands $item.preCommands
    }
    
    # Handle repository
    if ($item.repo) {
        $repoUrl = $item.repo.url
        $repoPath = Expand-EnvPath $item.repo.path
        
        Write-Host "Cloning repository: $repoUrl to $repoPath" -ForegroundColor Cyan
        
        # Create the destination directory if it doesn't exist
        if (-not (Test-Path $repoPath)) {
            New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
            Write-Host "Created directory: $repoPath" -ForegroundColor Green
        }
        
        Clone-Repository $repoUrl $repoPath
    }
    
    # Handle individual files
    if ($item.files) {
        foreach ($file in $item.files) {
            $fileUrl = $file.url
            $filePath = Expand-EnvPath $file.path
            $fileName = Split-Path $fileUrl -Leaf
            $outputPath = Join-Path $filePath $fileName
            
            Write-Host "Downloading file: $fileUrl to $outputPath" -ForegroundColor Cyan
            
            # Create the destination directory if it doesn't exist
            if (-not (Test-Path $filePath)) {
                New-Item -ItemType Directory -Path $filePath -Force | Out-Null
                Write-Host "Created directory: $filePath" -ForegroundColor Green
            }
            
            Download-File $fileUrl $outputPath
        }
    }
    
    # Execute post-commands if present
    if ($item.postCommands) {
        Write-Host "Executing post-commands for $($item.name)" -ForegroundColor Cyan
        Execute-Commands $item.postCommands
    }
}

Write-Host "`nConfiguration complete!" -ForegroundColor Green

# Clean up the temporary config file if it was downloaded
if ($configPath -like "$env:TEMP*") {
    Remove-Item $configPath
    Write-Host "Cleaned up temporary config file" -ForegroundColor Green
}

Write-Host "`nA system restart may be required for some changes to take effect." -ForegroundColor Yellow