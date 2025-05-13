# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

$TALKBACK_PACKAGE_NAME = "com.google.android.marvin.talkback"

# Function to check if adb exists at location and is executable
function Check-AdbLocation {
  param (
    [string]$location
  )
    
  if (Test-Path $location) {
    $script:ADB_LOCATION = $location
    Write-Host "adb found at: $location"
    return $true
  }
  return $false
}

# Function to find adb in common locations
function Find-Adb {
  $CURRENT_USER = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

  # Check if adb is available in PATH
  if (Get-Command adb -ErrorAction SilentlyContinue) {
    $script:ADB_LOCATION = "adb"
    Write-Host "adb found in PATH"
    return $true
  }

  # Possible adb locations for Windows
  $possibleLocations = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe",
    "C:\Android\Sdk\platform-tools\adb.exe",
    "C:\Program Files\Android\Sdk\platform-tools\adb.exe"
  )

  foreach ($location in $possibleLocations) {
    if (Check-AdbLocation $location) {
      return $true
    }
  }

  # If we still haven't found adb
  Write-Host "adb not found. Please either:"
  Write-Host "1. Install Android SDK Platform Tools and add it to your PATH, or"
  Write-Host "2. Move adb to any of the following locations"
  Write-Host ""
  Write-Host "Common installation locations checked:"
  $possibleLocations | ForEach-Object { Write-Host $_ }
  return $false
}

# Function to check if developer mode is enabled
function Check-DeveloperMode {
  $result = & $ADB_LOCATION shell settings get global development_settings_enabled 2>$null
  if (-not ($result -match "1")) {
    Write-Host "Developer mode is not enabled on the device."
    Write-Host "Please enable Developer mode by doing the following:"
    Write-Host "1. Go to Settings > About phone"
    Write-Host "2. Tap 'Build number' 7 times"
    Write-Host "3. Go back to Settings > System > Developer options"
    Write-Host "4. Enable 'Developer options'"
    Write-Host "5. Enable 'USB Debugging'"
    return $false
  }
  return $true
}

# Function to check if TalkBack is installed
function Check-TalkbackInstalled {
  $result = & $ADB_LOCATION shell pm list packages
  if (-not ($result -match $TALKBACK_PACKAGE_NAME)) {
    Write-Host "TalkBack is not installed on the device."
    Write-Host "Please install TalkBack from the Google Play Store."
    return $false
  }
  return $true
}

# Function to check if TalkBack is enabled
function Check-TalkbackEnabled {
  $result = & $ADB_LOCATION shell settings get secure enabled_accessibility_services
  return $result -match $TALKBACK_PACKAGE_NAME
}

# Function to enable TalkBack
function Enable-Talkback {
  & $ADB_LOCATION shell settings put secure enabled_accessibility_services "$TALKBACK_PACKAGE_NAME/$TALKBACK_PACKAGE_NAME.TalkBackService"
  & $ADB_LOCATION shell settings put secure accessibility_verbose_logging 1
  & $ADB_LOCATION shell settings put secure accessibility_enabled 1
}

# Function to disable TalkBack
function Disable-Talkback {
  & $ADB_LOCATION shell settings put secure enabled_accessibility_services "$TALKBACK_PACKAGE_NAME/NONE"
  & $ADB_LOCATION shell settings put secure accessibility_verbose_logging 0
  & $ADB_LOCATION shell settings put secure accessibility_enabled 0
}

# Function to clear logcat buffer
function Clear-Logcat {
  & $ADB_LOCATION logcat -c
}

# Function to check if Chrome is installed
function Check-ChromeInstalled {
  $result = & $ADB_LOCATION shell pm list packages
  if (-not ($result -match "com.android.chrome")) {
    Write-Host "Chrome is not installed on the device."
    Write-Host "Please install Chrome from the Google Play Store."
    return $false
  }
  return $true
}

# Function to open URL in Chrome
function Open-UrlInChrome {
  param (
    [string]$url
  )
  & $ADB_LOCATION shell am start -n com.android.chrome/com.google.android.apps.chrome.Main -a android.intent.action.VIEW -d $url
} 