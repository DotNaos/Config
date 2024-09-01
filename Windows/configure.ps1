# Define the URL for the config.json file
$configUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json"

# Download the config.json file
$configJson = Invoke-WebRequest -Uri $configUrl -UseBasicParsing | Select-Object -ExpandProperty Content

# Parse the JSON content
$config = $configJson | ConvertFrom-Json

# Function to clone a git repository
function Clone-GitRepo($repoUrl, $destinationPath) {
    # Ensure the destination directory exists
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -Path $destinationPath -ItemType Directory -Force
    }

    # Clone the git repository
    git clone $repoUrl $destinationPath
}

# Function to download a file
function Download-File($fileUrl, $destinationPath) {
    # Ensure the destination directory exists
    $destinationDirectory = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDirectory)) {
        New-Item -Path $destinationDirectory -ItemType Directory -Force
    }

    # Download the file and write it to the destination path
    $fileContent = Invoke-WebRequest -Uri $fileUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    Set-Content -Path $destinationPath -Value $fileContent -Force
}

# Iterate through each config in the JSON
foreach ($configItem in $config.configs) {
    # Clone the repository if specified
    if ($configItem.repo) {
        $repoUrl = $configItem.repo.url
        $destinationPath = Join-Path -Path $env:USERPROFILE -ChildPath $configItem.repo.path.TrimStart('/')
        Clone-GitRepo -repoUrl $repoUrl -destinationPath $destinationPath
    }

    # Download specific files if specified
    if ($configItem.files) {
        foreach ($file in $configItem.files) {
            $fileUrl = $file.url
            $destinationPath = Join-Path -Path $env:USERPROFILE -ChildPath $file.path.TrimStart('/')
            Download-File -fileUrl $fileUrl -destinationPath $destinationPath
        }
    }
}

Write-Output "Repositories and files have been successfully configured."
