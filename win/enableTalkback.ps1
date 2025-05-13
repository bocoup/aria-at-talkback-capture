# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

# Source the common functions
. "$SCRIPT_DIR\common.ps1"

if (-not (Find-Adb)) {
    exit 1
}

if (-not (Check-DeveloperMode)) {
    exit 1
}

if (-not (Check-TalkbackInstalled)) {
    exit 1
}

Write-Host "Enabling TalkBack..."
Enable-Talkback
Write-Host "TalkBack has been enabled." 