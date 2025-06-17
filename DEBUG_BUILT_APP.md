# Debugging the Built Electron App

## Issue: "Failed to check system status" in built version

The built version may have different file paths and execution contexts compared to the development version. Here's how to debug and fix this issue.

## Debugging Steps

### 1. Open Developer Tools in Built App

**Method 1: Keyboard Shortcut**
- Press `Ctrl+F12` (Windows/Linux) or `Cmd+F12` (macOS) to open developer tools

**Method 2: Debug Button**
- Click the "Debug Status" button in the app
- Check the console output and the capture output area

### 2. Check Console Logs

The app now includes detailed logging. Look for:
- Script path information
- File existence checks
- Execution errors
- Platform detection

### 3. Common Issues and Solutions

#### Issue: Script files not found
**Symptoms:**
- Console shows "Script not found" error
- Script path points to wrong location

**Solution:**
- Ensure scripts are included in the build
- Check `package.json` build configuration
- Verify `extraResources` section includes platform directories

#### Issue: Permission denied
**Symptoms:**
- Script exists but execution fails
- Permission errors in console

**Solution:**
- Make scripts executable: `chmod +x macos/*.sh linux/*.sh`
- Check file permissions in built app

#### Issue: Wrong working directory
**Symptoms:**
- Scripts can't find common.sh
- Relative path issues

**Solution:**
- Scripts use `SCRIPT_DIR` to find common.sh
- Verify working directory in built app

### 4. Manual Testing

Run the debug script to test script execution:

```bash
node debug-built-app.js
```

This will:
- Check if script files exist
- Verify file permissions
- Test script execution
- Show detailed output

### 5. Built App File Structure

The built app should have this structure:
```
ARIA-AT TalkBack Capture.app/Contents/Resources/
├── app/
│   ├── main.js
│   ├── preload.js
│   ├── renderer.js
│   ├── index.html
│   ├── styles.css
│   ├── macos/
│   │   ├── checkStatus.sh
│   │   ├── common.sh
│   │   └── ...
│   ├── linux/
│   │   ├── checkStatus.sh
│   │   ├── common.sh
│   │   └── ...
│   └── win/
│       ├── checkStatus.ps1
│       ├── common.ps1
│       └── ...
```

### 6. Environment Differences

**Development vs Built:**
- Development: Files in project directory
- Built: Files in app bundle with different paths
- Script execution context may differ

### 7. Troubleshooting Commands

Check if scripts are executable:
```bash
ls -la macos/*.sh linux/*.sh
```

Test script manually:
```bash
# macOS
./macos/checkStatus.sh

# Linux  
./linux/checkStatus.sh

# Windows
powershell -ExecutionPolicy Bypass -File win/checkStatus.ps1
```

### 8. Alternative Solutions

If the issue persists:

1. **Use absolute paths** in script execution
2. **Bundle scripts differently** using electron-builder
3. **Use Node.js native modules** instead of shell scripts
4. **Add more detailed error handling** and logging

### 9. Reporting Issues

When reporting issues, include:
- Platform (macOS/Windows/Linux)
- Electron version
- Console logs from developer tools
- Output from debug button
- Steps to reproduce

## Quick Fix Checklist

- [ ] Scripts are executable (`chmod +x`)
- [ ] Scripts are included in build (`package.json`)
- [ ] Developer tools show detailed logs
- [ ] Debug button provides useful information
- [ ] File paths are correct in built app
- [ ] Working directory is set correctly 