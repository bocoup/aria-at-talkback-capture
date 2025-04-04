#!/bin/sh

CURRENT_USER=$(whoami)

CLEAR_ADB_LOGS=false

while test $# -gt 0; do
  case "$1" in
  -h | --help)
    echo "options:"
    echo "-h, --help                show brief help"
    echo "-c, --clear-adb-logs      clear the device's adb logs after running this script"
    exit 0
    ;;
  -c | --clear-adb-logs)
    shift
    CLEAR_ADB_LOGS=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

# Check if adb exists at location and is executable
check_adb_location() {
  if [ -x "$1" ]; then
    ADB_LOCATION="$1"
    echo "adb found at: $1"
    return 0
  fi
  return 1
}

# Check if adb is available in PATH
if command -v adb >/dev/null 2>&1; then
  ADB_LOCATION="adb"
  echo "adb found in PATH, proceeding to capture logs..."
else
  # Possible adb locations
  for location in "/Users/$CURRENT_USER/Library/Android/sdk/platform-tools/adb" \
    "/Users/$CURRENT_USER/Android/sdk/platform-tools/adb" \
    "/opt/android-sdk/platform-tools/adb" \
    "/usr/local/opt/android-platform-tools/bin/adb" \
    "/usr/local/bin/adb" \
    "/usr/bin/adb" \
    "/opt/homebrew/bin/adb" \
    "/opt/homebrew/opt/android-platform-tools/bin/adb"; do
    if check_adb_location "$location"; then
      break
    fi
  done

  # If we still haven't found adb
  if [ -z "$ADB_LOCATION" ]; then
    echo "adb not found. Please either:"
    echo "1. Install Android SDK Platform Tools and add it to your PATH, or"
    echo "2. Move adb to any of the following locations"
    echo
    echo "Common installation locations checked:"
    echo "/Users/$CURRENT_USER/Library/Android/sdk/platform-tools/adb"
    echo "/Users/$CURRENT_USER/Android/sdk/platform-tools/adb"
    echo "/opt/android-sdk/platform-tools/adb"
    echo "/usr/local/opt/android-platform-tools/bin/adb"
    echo "/usr/local/bin/adb"
    echo "/usr/bin/adb"
    echo "/opt/homebrew/bin/adb"
    echo "/opt/homebrew/opt/android-platform-tools/bin/adb"
    exit 1
  fi
fi

SCRIPT_DIR="$(dirname "$0")"
TALKBACK_PACKAGE_NAME="com.google.android.marvin.talkback"

# Capture TalkBack logs on Android using adb logcat
TALKBACK_LOGS_OUTPUT="$SCRIPT_DIR/talkback_capture.log"

echo "Capturing TalkBack logs at $TALKBACK_LOGS_OUTPUT ..."

$ADB_LOCATION logcat --pid=$($ADB_LOCATION shell pidof -s $TALKBACK_PACKAGE_NAME) -v threadtime -d >$TALKBACK_LOGS_OUTPUT

if [ $? -eq 0 ]; then
  echo "TalkBack logs captured successfully at $TALKBACK_LOGS_OUTPUT"
  if [ "$CLEAR_ADB_LOGS" = true ]; then
    echo "Clearing adb logs..."
    $ADB_LOCATION logcat -c
  fi
else
  echo "Failed to capture TalkBack logs. Please check if TalkBack is running."
  exit 1
fi
