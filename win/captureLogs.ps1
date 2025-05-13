# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

# Source the common functions
. "$SCRIPT_DIR\common.ps1"

$TALKBACK_PACKAGE_NAME = "com.google.android.marvin.talkback"
$TALKBACK_LOGS_OUTPUT = Join-Path $ROOT_DIR "talkback_capture.log"

# Flags
$CLEAR_ADB_LOGS = $false

# Parse command line arguments
$args = $args | ForEach-Object {
    switch ($_) {
        "-h" { 
            Write-Host "options:"
            Write-Host "-h, --help                show brief help"
            Write-Host "-c, --clear-adb-logs      clear the device's adb logs after running this script"
            exit 0
        }
        "--help" { 
            Write-Host "options:"
            Write-Host "-h, --help                show brief help"
            Write-Host "-c, --clear-adb-logs      clear the device's adb logs after running this script"
            exit 0
        }
        "-c" { $CLEAR_ADB_LOGS = $true }
        "--clear-adb-logs" { $CLEAR_ADB_LOGS = $true }
        default { $_ }
    }
}

# Check if adb is available
if (-not (Find-Adb)) {
    exit 1
}

# Check if developer mode is enabled
if (-not (Check-DeveloperMode)) {
    exit 1
}

Write-Host "Capturing TalkBack logs at $TALKBACK_LOGS_OUTPUT ..."

# Get the TalkBack process ID and capture logs
$pid = & $ADB_LOCATION shell pidof -s $TALKBACK_PACKAGE_NAME
if ($LASTEXITCODE -eq 0) {
    & $ADB_LOCATION logcat --pid=$pid -v threadtime -d > $TALKBACK_LOGS_OUTPUT
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "TalkBack logs captured successfully at $TALKBACK_LOGS_OUTPUT"
        if ($CLEAR_ADB_LOGS) {
            Write-Host "Clearing adb logs..."
            Clear-Logcat
        }
    } else {
        Write-Host "Failed to capture TalkBack logs. Please check if TalkBack is running."
        exit 1
    }
} else {
    Write-Host "Failed to get TalkBack process ID. Please check if TalkBack is running."
    exit 1
} 