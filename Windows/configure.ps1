# URL of the config.json file in the same repository
$configUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"

# Download and parse config.json
$configJson = Invoke-RestMethod -Uri $configUrl

# Function to clone a Git repository
function Clone-Repo {
    param (
        [string]$url,
        [string]$path
    )

    Write-Host "Cloning repository from $url to $path..."
    git clone $url $path
    Write-Host "Repository cloned successfully."
}

# Function to download a file
function Download-File {
    param (
        [string]$url,
        [string]$path
    )

    Write-Host "Downloading file from $url to $path..."
    
    # Ensure the destination directory exists
    $destDir = Split-Path $path
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory | Out-Null
    }

    # Download the file to the destination
    Invoke-WebRequest -Uri $url -OutFile $path
    Write-Host "File downloaded successfully."
}

# Function to set a registry key
function Set-Registry {
    param (
        [string]$key,
        [string]$name,
        [string]$value,
        [string]$type
    )

    Write-Host "Setting registry key $key, name $name, value $value, type $type..."
    Set-ItemProperty -Path $key -Name $name -Value $value -PropertyType $type -Force
    Write-Host "Registry key set successfully."
}

# Process repositories and files
foreach ($config in $configJson.configs) {
    if ($config.repo) {
        Clone-Repo -url $config.repo.url -path (Invoke-Expression $config.repo.path)
    }

    if ($config.files) {
        foreach ($file in $config.files) {
            Download-File -url $file.url -path (Invoke-Expression $file.path)
        }
    }
}

# Process registry settings
foreach ($reg in $configJson.registry) {
    Set-Registry -key $reg.key -name $reg.name -value $reg.value -type $reg.type
}

Write-Host "All configurations and registry settings have been applied."
