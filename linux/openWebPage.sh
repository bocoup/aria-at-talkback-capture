#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the common functions
. "$SCRIPT_DIR/common.sh"

# Check if URL is provided
if [ $# -eq 0 ]; then
  echo "Please provide a URL to open."
  echo "Usage: ./openWebPage.sh <url>"
  exit 1
fi

url="$1"

# Check if adb is available
if ! find_adb; then
  exit 1
fi

# Check if developer mode is enabled
if ! check_developer_mode; then
  exit 1
fi

# Check if Chrome is installed
if ! check_chrome_installed; then
  exit 1
fi

# Open the URL in Chrome
echo "Opening $url in Chrome..."
open_url_in_chrome "$url"

if [ $? -eq 0 ]; then
  echo "URL opened successfully in Chrome"
else
  echo "Failed to open URL in Chrome"
  exit 1
fi
