# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source the common functions
. "$SCRIPT_DIR\common.ps1"

Write-Host "=== System Status Check ===" -ForegroundColor Cyan

# Check if adb is available
Write-Host "Checking ADB availability..." -ForegroundColor Yellow
if (Find-Adb) {
    Write-Host "✅ ADB found at: $ADB_LOCATION" -ForegroundColor Green
    
    # Check if device is connected
    Write-Host "Checking device connection..." -ForegroundColor Yellow
    $devices = & $ADB_LOCATION devices
    if ($devices -match "device$") {
        Write-Host "✅ Device connected" -ForegroundColor Green
        
        # Check developer mode
        Write-Host "Checking developer mode..." -ForegroundColor Yellow
        if (Test-DeveloperMode) {
            Write-Host "✅ Developer mode enabled" -ForegroundColor Green
            
            # Check TalkBack installation
            Write-Host "Checking TalkBack installation..." -ForegroundColor Yellow
            if (Test-TalkbackInstalled) {
                Write-Host "✅ TalkBack is installed" -ForegroundColor Green
                
                # Check TalkBack status
                Write-Host "Checking TalkBack status..." -ForegroundColor Yellow
                if (Test-TalkbackEnabled) {
                    Write-Host "✅ TalkBack is enabled" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  TalkBack is not enabled" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ TalkBack is not installed" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Developer mode not enabled" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ No device connected" -ForegroundColor Red
    }
} else {
    Write-Host "❌ ADB not found" -ForegroundColor Red
}

Write-Host "=== Status Check Complete ===" -ForegroundColor Cyan 