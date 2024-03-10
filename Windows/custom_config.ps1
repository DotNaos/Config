$url = Read-Host "Provide url custom config .ps1 file"

# Check if the user entered a valid URL
# And if the file is a .ps1 file
if (-not ($url -match "^(https?|ftp)://[^\s/$.?#].[^\s]*\.ps1$"
)) {
    Write-Host "Invalid URL"
    exit
}

iex ((New-Object System.Net.WebClient).DownloadString($url))
