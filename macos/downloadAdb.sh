#!/bin/bash

# Function to add to PATH
add_to_path() {
  local adb_dir="$1"
  local shell_files=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc")
  local path_added=false

  for shell_file in "${shell_files[@]}"; do
    if [[ -f "$shell_file" ]]; then
      # Check if the path is already in the file
      if ! grep -q "export PATH=\"$adb_dir:\$PATH\"" "$shell_file"; then
        echo "export PATH=\"$adb_dir:\$PATH\"" >>"$shell_file"
        echo "Added ADB to PATH in $(basename "$shell_file")"
        path_added=true
      else
        echo "ADB path already exists in $(basename "$shell_file")"
        path_added=true
      fi
    fi
  done

  if [[ "$path_added" == "true" ]]; then
    echo "Please run 'source ~/.zshrc' or 'source ~/.bash_profile' (depending on your shell) or restart your terminal to apply changes"
  else
    echo "Could not find any shell configuration files"
  fi
}

# Function to download ADB
download_adb() {
  echo "Downloading platform-tools for macOS..."

  # Create a temporary directory for download
  local temp_dir="$HOME/Library/Caches/platform-tools-temp"
  # Remove existing directory if it exists
  rm -rf "$temp_dir"
  mkdir -p "$temp_dir"

  # Download platform-tools
  curl -L "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip" -o "$temp_dir/platform-tools.zip"
  unzip -q "$temp_dir/platform-tools.zip" -d "$temp_dir"

  # Get the absolute path to the platform-tools directory
  local adb_dir="$(cd "$temp_dir/platform-tools" && pwd)"

  # Add to PATH for current session
  export PATH="$adb_dir:$PATH"

  # Add to permanent PATH
  add_to_path "$adb_dir"

  echo "ADB downloaded and added to PATH"
  echo "For permanent installation, please download platform-tools from:"
  echo "https://developer.android.com/studio/releases/platform-tools"
}

# Main script
download_adb

echo "ADB setup complete. You can now use ADB commands."
