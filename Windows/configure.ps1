# Function to download a file from a URL
function Download-File($url, $outputPath) {
    Invoke-WebRequest -Uri $url -OutFile $outputPath
}

# Function to clone a GitHub repository
function Clone-Repository($url, $outputPath) {
    git clone $url $outputPath
}

# Function to expand environment variables in a path
function Expand-EnvPath($path) {
    return [System.Environment]::ExpandEnvironmentVariables($path)
}

# Download the config.json file
$configUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"
$configPath = Join-Path $env:TEMP "config.json"
Download-File $configUrl $configPath

# Read the config.json file
$config = Get-Content $configPath | ConvertFrom-Json

# Process each configuration item
foreach ($item in $config.configs) {
    Write-Host "Processing configuration: $($item.name)"
    
    # Handle repository
    if ($item.repo) {
        $repoUrl = $item.repo.url
        $repoPath = Expand-EnvPath $item.repo.path
        
        # Create the destination directory if it doesn't exist
        if (-not (Test-Path $repoPath)) {
            New-Item -ItemType Directory -Path $repoPath -Force
        }
        
        Clone-Repository $repoUrl $repoPath
        Write-Host "Cloned repository: $repoUrl to $repoPath"
    }
    
    # Handle individual files
    if ($item.files) {
        foreach ($file in $item.files) {
            $fileUrl = $file.url
            $filePath = Expand-EnvPath $file.path
            $fileName = Split-Path $fileUrl -Leaf
            $outputPath = Join-Path $filePath $fileName
            
            # Create the destination directory if it doesn't exist
            if (-not (Test-Path $filePath)) {
                New-Item -ItemType Directory -Path $filePath -Force
            }
            
            Download-File $fileUrl $outputPath
            Write-Host "Downloaded file: $fileUrl to $outputPath"
        }
    }
}

Write-Host "Configuration complete!"

# Clean up the temporary config file
Remove-Item $configPath