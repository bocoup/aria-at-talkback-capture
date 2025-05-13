# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

# Source the common functions
. "$SCRIPT_DIR\common.ps1"

# Check if URL is provided
if ($args.Count -eq 0) {
    Write-Host "Please provide a URL to open."
    Write-Host "Usage: .\openWebPage.ps1 <url>"
    exit 1
}

$url = $args[0]

if (-not (Find-Adb)) {
    exit 1
}

if (-not (Check-DeveloperMode)) {
    exit 1
}

if (-not (Check-ChromeInstalled)) {
    exit 1
}

Write-Host "Opening $url in Chrome..."
Open-UrlInChrome $url 