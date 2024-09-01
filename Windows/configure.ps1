# Load configuration from config.json
$configUrl = 'https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json'
$config = Invoke-WebRequest -Uri $configUrl -UseBasicParsing | ConvertFrom-Json

# Set log file path
$logFilePath = Join-Path -Path $env:TEMP -ChildPath 'configure-pc.log'

# Function to write log
function Write-Log {
  param (
    [string]$Message,
    [string]$Level = 'INFO'
  )

  $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Level - $Message"
  Add-Content -Path $logFilePath -Value $logEntry
  Write-Host $logEntry
}

# Function to download and extract repository
function Download-Repository {
  param (
    [string]$Url,
    [string]$Path
  )

  Write-Log -Message "Downloading repository from $Url to $Path" -Level 'DEBUG'
  try {
    # Download repository
    $repoName = $Url.Split('/')[-1]
    $repoPath = Join-Path -Path $Path -ChildPath $repoName
    if (Test-Path -Path $repoPath) {
      Remove-Item -Path $repoPath -Recurse -Force
    }
    git clone $Url $repoPath

    # Copy files to destination path
    $files = Get-ChildItem -Path $repoPath -Recurse -File
    foreach ($file in $files) {
      $destPath = Join-Path -Path $Path -ChildPath ($file.FullName -replace [regex]::Escape($repoPath))
      $destDir = Split-Path -Path $destPath -Parent
      if (!(Test-Path -Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force
      }
      Copy-Item -Path $file.FullName -Destination $destPath -Force
    }
    Write-Log -Message "Repository downloaded and extracted successfully" -Level 'INFO'
  } catch {
    Write-Log -Message "Error downloading repository: $($Error[0].Message)" -Level 'ERROR'
  }
}

# Function to download file
function Download-File {
  param (
    [string]$Url,
    [string]$Path
  )

  Write-Log -Message "Downloading file from $Url to $Path" -Level 'DEBUG'
  try {
    # Download file
    $fileName = $Url.Split('/')[-1]
    $filePath = Join-Path -Path $Path -ChildPath $fileName
    Invoke-WebRequest -Uri $Url -OutFile $filePath
    Write-Log -Message "File downloaded successfully" -Level 'INFO'
  } catch {
    Write-Log -Message "Error downloading file: $($Error[0].Message)" -Level 'ERROR'
  }
}

# Configure PC
Write-Log -Message 'Starting configuration' -Level 'INFO'
foreach ($configItem in $config.configs) {
  if ($configItem.repo.url) {
    Download-Repository -Url $configItem.repo.url -Path $configItem.repo.path
  }
  if ($configItem.files) {
    foreach ($file in $configItem.files) {
      Download-File -Url $file.url -Path $file.path
    }
  }
}

# Configure registry
if ($config.registry) {
  Write-Log -Message 'Configuring registry' -Level 'INFO'
  foreach ($registryItem in $config.registry) {
    $key = $registryItem.key
    $name = $registryItem.name
    $value = $registryItem.value
    $type = $registryItem.type

    Write-Log -Message "Setting registry key $key\$name to $value" -Level 'DEBUG'
    try {
      if (!(Test-Path -Path $key)) {
        New-Item -Path $key -ItemType Key -Force
      }
      Set-ItemProperty -Path $key -Name $name -Value $value -Type $type -Force
      Write-Log -Message "Registry key set successfully" -Level 'INFO'
    } catch {
      Write-Log -Message "Error setting registry key: $($Error[0].Message)" -Level 'ERROR'
    }
  }
}
Write-Log -Message 'Configuration complete' -Level 'INFO'