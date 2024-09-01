# Load the JSON configuration file
$configFile = (Join-Path $PSScriptRoot 'config.json')
$configs = Get-Content -Raw -Path $configFile | ConvertFrom-Json

# Function to download and extract a GitHub repository
function Download-GitHubRepo {
    param (
        [string]$repoUrl,
        [string]$destinationPath
    )
    
    # Ensure the destination directory exists
    if (-not (Test-Path $destinationPath)) {
        Write-Host "Creating directory $destinationPath"
        New-Item -ItemType Directory -Force -Path $destinationPath
    }

    # Construct the URL to download the repo as a ZIP file
    $zipUrl = "$repoUrl/archive/refs/heads/main.zip"
    $zipFile = Join-Path $env:TEMP ('repo.zip')

    # Download the ZIP file
    Write-Host "Downloading repository from $repoUrl..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing

    # Extract the ZIP file
    Write-Host "Extracting to $destinationPath..."
    Expand-Archive -Path $zipFile -DestinationPath $destinationPath -Force

    # Move contents from the extracted folder to the final destination if needed
    $extractedFolder = Join-Path $destinationPath (Get-ChildItem -Path $destinationPath | Select-Object -First 1).Name
    Move-Item -Path "$extractedFolder\*" -Destination $destinationPath -Force

    # Cleanup: Remove the extracted folder and zip file
    Remove-Item -Path $extractedFolder -Recurse -Force
    Remove-Item -Path $zipFile -Force

    Write-Host "Repository has been downloaded and extracted to $destinationPath."
}

# Function to set registry values
function Set-RegistryValues {
    param (
        [string]$key,
        [hashtable]$values
    )
    
    # Ensure the registry key exists
    if (-not (Test-Path $key)) {
        Write-Host "Creating registry key $key"
        New-Item -Path $key -Force
    }

    # Set each value in the registry key
    foreach ($name in $values.Keys) {
        $valueType = $values[$name].type
        $valueData = $values[$name].value

        Write-Host "Setting registry value $name of type $valueType with data $valueData in key $key"
        Set-ItemProperty -Path $key -Name $name -Value $valueData -PropertyType $valueType -Force
    }
}

# Loop through each configuration in the JSON
foreach ($config in $configs.configs) {
    Write-Host "Processing $($config.name) configuration..."

    # If a repository is specified, download and extract it
    if ($config.repo) {
        Download-GitHubRepo -repoUrl $config.repo.url -destinationPath $config.repo.path
    }

    # If individual files are specified, download them
    if ($config.files) {
        foreach ($file in $config.files) {
            $url = $file.url
            $destinationPath = $file.path

            # Ensure the destination directory exists
            if (-not (Test-Path $destinationPath)) {
                Write-Host "Creating directory $destinationPath"
                New-Item -ItemType Directory -Force -Path $destinationPath
            }

            # Extract the filename from the URL
            $filename = Split-Path $url -Leaf

            # Define the full path where the file will be saved
            $destinationFile = Join-Path $destinationPath $filename

            # Download the file
            Write-Host "Downloading $filename from $url..."
            Invoke-WebRequest -Uri $url -OutFile $destinationFile -UseBasicParsing

            Write-Host "$filename has been downloaded and copied to $destinationPath."
        }
    }
}

# Apply registry configurations if specified
if ($configs.registry) {
    foreach ($regConfig in $configs.registry) {
        $key = $regConfig.key
        $values = $regConfig.values

        Set-RegistryValues -key $key -values $values
    }
}

Write-Host "Configuration setup complete."
