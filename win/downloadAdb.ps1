# Function to add to PATH
function Add-ToPath {
    param (
        [string]$adbDir
    )
    
    # Get the current user's PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Check if the path is already in the PATH
    if (-not $currentPath.Contains($adbDir)) {
        # Add the new path
        $newPath = "$currentPath;$adbDir"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "Added ADB to Windows PATH permanently"
    } else {
        Write-Host "ADB path already exists in PATH"
    }
}

# Function to download ADB
function Download-Adb {
    Write-Host "Downloading platform-tools for Windows..."
    
    # Create a temporary directory for download
    $tempDir = Join-Path $env:TEMP "platform-tools-temp"
    # Remove existing directory if it exists
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Download platform-tools
    $zipFile = Join-Path $tempDir "platform-tools.zip"
    $downloadUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile
    } catch {
        Write-Host "Failed to download platform-tools. Error: $_"
        exit 1
    }
    
    # Extract the zip file
    try {
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
    } catch {
        Write-Host "Failed to extract platform-tools. Error: $_"
        exit 1
    }
    
    # Get the absolute path to the platform-tools directory
    $adbDir = Join-Path $tempDir "platform-tools"
    $adbDir = (Get-Item $adbDir).FullName
    
    # Add to PATH for current session
    $env:PATH = "$adbDir;$env:PATH"
    $script:ADB_PATH = Join-Path $adbDir "adb.exe"
    
    # Add to permanent PATH
    Add-ToPath $adbDir
    
    Write-Host "ADB downloaded and added to PATH"
    Write-Host "For permanent installation, please download platform-tools from:"
    Write-Host "https://developer.android.com/studio/releases/platform-tools"
}

# Main script
try {
    Download-Adb
    Write-Host "ADB setup complete. You can now use ADB commands."
} catch {
    Write-Host "An error occurred: $_"
    exit 1
} 