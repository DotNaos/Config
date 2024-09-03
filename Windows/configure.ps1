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

# Prompt user for custom config file
$customConfig = Read-Host "Enter a URL or local file path for a custom config.json (or press Enter for default)"

# Set the config path
if ([string]::IsNullOrWhiteSpace($customConfig)) {
    $configUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"
    $configPath = Join-Path $env:TEMP "config.json"
    Write-Host "Using default config file from $configUrl" -ForegroundColor Cyan
    Download-File $configUrl $configPath
}
elseif ($customConfig -match '^https?://') {
    $configUrl = $customConfig
    $configPath = Join-Path $env:TEMP "config.json"
    Write-Host "Downloading custom config file from $configUrl" -ForegroundColor Cyan
    Download-File $configUrl $configPath
}
else {
    $configPath = Expand-EnvPath $customConfig
    if (Test-Path $configPath) {
        Write-Host "Using local config file: $configPath" -ForegroundColor Cyan
    }
    else {
        Write-Host "Error: Local config file not found at $configPath" -ForegroundColor Red
        exit
    }
}

# Read the config.json file
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "Successfully loaded config.json" -ForegroundColor Green
}
catch {
    Write-Host "Error parsing config.json: $_" -ForegroundColor Red
    exit
}

# Execute pre-configuration commands
Write-Host "`nExecuting pre-configuration commands" -ForegroundColor Yellow
if ($config.preCommands) {
    Execute-Commands $config.preCommands
}

# Process each configuration item
foreach ($item in $config.configs) {
    Write-Host "`nProcessing configuration: $($item.name)" -ForegroundColor Yellow
    
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
}

# Execute post-configuration commands
Write-Host "`nExecuting post-configuration commands" -ForegroundColor Yellow
if ($config.postCommands) {
    Execute-Commands $config.postCommands
}

Write-Host "`nConfiguration complete!" -ForegroundColor Green

# Clean up the temporary config file if it was downloaded
if ($configPath -like "$env:TEMP*") {
    Remove-Item $configPath
    Write-Host "Cleaned up temporary config file" -ForegroundColor Green
}