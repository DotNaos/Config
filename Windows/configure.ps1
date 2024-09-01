# PC Configuration Script

# Function to download and copy config files
function Copy-ConfigFiles {
    param (
        [string]$repoUrl,
        [string]$localPath
    )
    
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($localPath)
    
    # Clone the repository
    Write-Host "Cloning repository from $repoUrl to temp directory..."
    git clone $repoUrl temp_repo
    
    # Create the destination directory if it doesn't exist
    if (!(Test-Path $expandedPath)) {
        New-Item -Path $expandedPath -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $expandedPath"
    }
    
    # Copy files to the specified local path
    Write-Host "Copying files to $expandedPath..."
    Copy-Item -Path "temp_repo\*" -Destination $expandedPath -Recurse -Force
    
    # Clean up
    Remove-Item -Path "temp_repo" -Recurse -Force
    Write-Host "Cleaned up temporary files."
}

# Function to prompt for credentials and update config files
function Update-ConfigWithCredentials {
    param (
        [string]$configPath,
        [string[]]$credentialKeys
    )
    
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($configPath)
    $content = Get-Content $expandedPath -Raw
    
    foreach ($key in $credentialKeys) {
        $value = Read-Host "Enter value for $key"
        $content = $content -replace "{{$key}}", $value
    }
    
    $content | Set-Content $expandedPath
    Write-Host "Updated configuration file with credentials: $expandedPath"
}

# Function to modify registry
function Set-RegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$value,
        [string]$type
    )
    
    if (!(Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
        Write-Host "Created new registry key: $path"
    }
    
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
    Write-Host "Set registry value: $path\$name = $value ($type)"
}
# Main script with URL
$configJson = Get-Content "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json" | ConvertFrom-Json

# Process copy_config tasks
Write-Host "Starting configuration file copy tasks..."
foreach ($task in $configJson.copy_config) {
    Write-Host "Processing task: $($task.description)"
    Copy-ConfigFiles -repoUrl $task.repoUrl -localPath $task.localPath
    if ($task.requiresCredentials) {
        $fullPath = Join-Path $task.localPath $task.credentialFile
        Update-ConfigWithCredentials -configPath $fullPath -credentialKeys $task.credentialKeys
    }
}

# Process registry tasks
Write-Host "`nStarting registry modification tasks..."
foreach ($task in $configJson.registry) {
    Write-Host "Processing task: $($task.description)"
    Set-RegistryValue -path $task.path -name $task.name -value $task.value -type $task.valueType
}

Write-Host "`nPC configuration completed successfully!"