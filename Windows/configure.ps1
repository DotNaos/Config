# Load configuration from config.json
$configUrl = 'https://raw.githubusercontent.com/DotNaos/Config/main/Windows/config.json'
$config = Invoke-WebRequest -Uri $configUrl -UseBasicParsing | ConvertFrom-Json

# Function to download and extract repository
function Download-Repository {
  param (
    [string]$Url,
    [string]$Path
  )

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
}

# Function to download file
function Download-File {
  param (
    [string]$Url,
    [string]$Path
  )

  # Download file
  $fileName = $Url.Split('/')[-1]
  $filePath = Join-Path -Path $Path -ChildPath $fileName
  Invoke-WebRequest -Uri $Url -OutFile $filePath
}

# Configure PC
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
  foreach ($registryItem in $config.registry) {
    $key = $registryItem.key
    $name = $registryItem.name
    $value = $registryItem.value
    $type = $registryItem.type

    if (!(Test-Path -Path $key)) {
      New-Item -Path $key -ItemType Key -Force
    }
    Set-ItemProperty -Path $key -Name $name -Value $value -Type $type -Force
  }
}