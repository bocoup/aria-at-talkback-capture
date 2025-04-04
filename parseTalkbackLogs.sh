#!/bin/sh

CURRENT_USER=$(whoami)
SCRIPT_DIR="$(dirname "$0")"

TALKBACK_PACKAGE_NAME="com.google.android.marvin.talkback"
UTTERANCES_LOG="$SCRIPT_DIR/utterances.log"

# Initialize temporary utterances file; remove on interrupt
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

VERBOSE=false
DISPLAY_ALL_LINES=false

while test $# -gt 0; do
  case "$1" in
  -h | --help)
    echo "options:"
    echo "-h, --help                show brief help"
    echo "-v, --verbose             show entire TalkBack output line for any given utterance"
    echo "-a, --display-all-lines   show all TalkBack output lines, even if no clear utterances to be captured. \"--verbose\" will be automatically enabled"
    exit 0
    ;;
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  -a | --display-all-lines)
    VERBOSE=true
    DISPLAY_ALL_LINES=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

# Handle Ctrl+C interrupt to capture the collected utterances
cleanup() {
  echo "\n\nCollected utterances:"
  if [ -s "$TEMP_FILE" ]; then
    utterances=$(cat "$TEMP_FILE")
    echo "$utterances"
    # Copy to clipboard
    echo "$utterances" | pbcopy
    echo "\nCopied to clipboard"
  else
    echo "No utterances were collected."
  fi
  exit 0
}

# Set up trap for Ctrl+C
trap cleanup INT

# Check if adb exists at location and is executable
check_adb_location() {
  if [ -x "$1" ]; then
    ADB_LOCATION="$1"
    echo "adb found at: $1"
    return 0
  fi
  return 1
}

# Check if developer mode is enabled
check_developer_mode() {
  if ! $ADB_LOCATION shell settings get global development_settings_enabled 2>/dev/null | grep -q "1"; then
    echo "Developer mode is not enabled on the device."
    echo "Please enable Developer mode by:"
    echo "1. Go to Settings > About phone"
    echo "2. Tap 'Build number' 7 times"
    echo "3. Go back to Settings > System > Developer options"
    echo "4. Enable 'Developer options'"
    return 1
  fi
  return 0
}

# Check if adb is available in PATH
if command -v adb >/dev/null 2>&1; then
  ADB_LOCATION="adb"
  echo "adb found in PATH"
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

# Check if developer mode is enabled
if ! check_developer_mode; then
  exit 1
fi

echo "Starting to capture TalkBack logs..."
echo "Please press the 'Run Test Setup' button now..."
echo "Press Ctrl+C to stop capturing logs when finished\n"

# Clear any existing logcat buffer
$ADB_LOCATION logcat -c

# Start capturing logs and filter for TalkBack utterances
$ADB_LOCATION logcat --pid=$($ADB_LOCATION shell pidof -s $TALKBACK_PACKAGE_NAME) | grep -i "talkback\|utterance" | while read -r line; do
  # Look for ACTION_CLICK and Run Test Setup in the same line
  # https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo.AccessibilityAction#ACTION_CLICK
  if echo "$line" | grep -q "ACTION_CLICK.*Run Test Setup"; then
    echo "Found 'Run Test Setup' button press"
    # Continue capturing the next utterances
    while read -r next_line; do
      if [ "$DISPLAY_ALL_LINES" = true ]; then
        echo "$next_line"
      fi

      # Extract text from lines containing "text="
      if echo "$next_line" | grep -q "utterance"; then
        if [ "$VERBOSE" = true ] && [ "$DISPLAY_ALL_LINES" = false ]; then
          echo "$next_line"
        fi

        new_utterance=$(echo "$next_line" | sed 's/.*text="\([^"]*\)".*/\1/')
        echo "$new_utterance"

        # Join the utterances with double spaces. This is to match how other ATs' utterances have been getting captured; TODO: may not be necessary)
        printf "%s  " "$new_utterance" >> "$TEMP_FILE"
      fi
    done
  fi
done
