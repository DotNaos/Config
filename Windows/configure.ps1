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

# Download the config.json file
$configUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"
$configPath = Join-Path $env:TEMP "config.json"
Write-Host "Downloading config file from $configUrl" -ForegroundColor Cyan
Download-File $configUrl $configPath

# Read the config.json file
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "Successfully loaded config.json" -ForegroundColor Green
}
catch {
    Write-Host "Error parsing config.json: $_" -ForegroundColor Red
    exit
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

Write-Host "`nConfiguration complete!" -ForegroundColor Green

# Clean up the temporary config file
Remove-Item $configPath
Write-Host "Cleaned up temporary config file" -ForegroundColor Green