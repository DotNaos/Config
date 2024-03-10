# Prompt user for own url
$url = Read-Host "Provide url for package.config file"

# Check if the user entered a valid URL
# And if the file is a .config file
if (-not ($url -match "^(https?|ftp)://[^\s/$.?#].[^\s]*\.config$"
)) {
    Write-Host "Invalid URL"
    exit
}

$out = [System.IO.Path]::GetTempPath()
$out = $out + "//choco//custom.config" # Path to the directory where the packages will be downloaded

# Download the custom install script
Invoke-WebRequest -Uri $url -OutFile $out

# Install the custom packages
choco install -y $out

