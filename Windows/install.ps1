# Base URL for the packages
$baseUrl = "https://raw.githubusercontent.com/DotNaos/Config/main/Windows/packages/"

# List of packages to install
$packages = @(
    "misc.config",
    "gaming.config",
    "cli.config",
    "dev.config",
    "design.config"
    # "python.config"
)

$out = [System.IO.Path]::GetTempPath()

$out = $out + "//choco//" # Path to the directory where the packages will be downloaded
# Make sure the directory exists
if (-not (Test-Path $out)) {
    New-Item -ItemType Directory -Path $out
}

foreach ($package in $packages) {
    $dest = $out + $package
    $url = $baseUrl + $package
    Invoke-WebRequest -Uri $url -OutFile $dest
    choco install -y $dest
}

