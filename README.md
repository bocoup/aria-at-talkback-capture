# ARIA-AT TalkBack Capture

This repository contains prototyping scripts for capturing TalkBack utterances on Android devices. Intended to serve the purposes of [ARIA-AT](https://aria-at.w3.org).

## Background

This was incepted as a native Android application. Such that a user would be able to have the application capture the relevant utterances in the background, after the "Run Test Setup" button on a test was pressed. They would be provided with some widget or return to the application to immediately copy the utterances found and paste into the relevant output field(s). After more discussions and consideration of the potential users to engage with such a product, it made more sense to segue due to, but not limited to:

1. Less interest today in providing a fully built out responsive experience for [ARIA-AT](https://aria-at.w3.org).
2. Comfort with ARIA-AT through desktop has already been established so requiring heavy usage on a mobile platform may be less appealing.

The result of that are the following scripts. The idea is these scripts can potentially be served behind some extension of the ARIA-AT web app, it's own tiny web app or some desktop-based app.

## Cross-Platform GUI Application

A new Electron-based GUI application has been added to provide a user-friendly interface for all TalkBack capture operations. The app works on Windows, macOS, and Linux.

### Features

- **System Status Monitoring**: Check ADB connection, device status, and TalkBack status
- **TalkBack Control**: Enable and disable TalkBack with a single click
- **Web Page Control**: Open URLs directly in Chrome on the connected Android device
- **Real-time Utterance Capture**: Start/stop capture with live streaming of utterances
- **Output Management**: Copy captured text to clipboard or save to file
- **Cross-platform Support**: Works on Windows, macOS, and Linux

### Installation and Usage

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Run in Development Mode**:
   ```bash
   npm run dev
   ```

3. **Build for Distribution**:
   ```bash
   # Build for all platforms
   npm run build
   
   # Build for specific platform
   npm run build:win    # Windows
   npm run build:mac    # macOS
   npm run build:linux  # Linux
   ```

4. **Prerequisites**:
   - Node.js and npm installed
   - ADB (Android Debug Bridge) installed and in PATH
   - Android device connected via USB with USB debugging enabled

## Scripts

### enableTalkback.sh

Enables TalkBack on the connected Android device and turns on accessibility logging.

### disableTalkback.sh

Disables TalkBack on the connected Android device and turns off accessibility logging.

### captureUtterances.sh

Captures TalkBack spoken output from when the "Run Test Setup" button is pressed until either:

- "End of Example" is encountered
- Or an interrupt (eg. Ctrl+C is pressed)

The script will:

- Filter and extract the actual spoken text from TalkBack logs
- Display the utterances in real-time
- Save and copy all collected utterances to clipboard when finished

Options:

- `-h, --help`: Display help information
- `-a, --display-all-lines`: Show all TalkBack log lines, even those without utterances
- `-v, --verbose`: Show the full TalkBack log line for each utterance

### openWebPage.sh

Opens a specified URL in Chrome on the connected Android device. This would be useful to immediately open the tester's Run and Example page on their device to begin testing.

Example Usage:

```bash
openWebPage.sh https://example.com
```

### captureLogs.sh

Captures and saves all TalkBack-related device logs to `./talkback_capture.log` file. Useful for debugging.

Options:

- `-h, --help`: Display help information
- `-c, --clear-adb-logs`: Clear the logcat buffer after capturing the logs

## Prerequesites

An installed version of [ADB](https://developer.android.com/tools/adb) is required. Preferred for it to be included on your PATH (otherwise, it will be searched for in likely locations).

### Installing System ADB

1. **macOS**: Install via Homebrew:

    ```bash
    brew install android-platform-tools
    ```

2. **Linux**: TODO

3. **Windows**: TODO

## Usage

1. Connect your Android device via USB
2. Enable Developer Options on your device
3. Enable USB Debugging in Developer Options
4. Run the desired script based on your testing needs

## TODO

- Bundle adb.
- Adding cross-platform support. The scripts were developed with MacOS in mind (which shows by the adb location assumptions, copy utils, etc). This should be extended to Linux and Windows platforms.
- Security considerations around the `openWebPage.sh` script.
- There's a speaker queue coming from TalkBack which is sometimes different from the utterances lines being captured. One-off instances have popped up where the difference is significant enough that an utterance could be missed. This should be made more robust to combine both sources.
- Investigating basic CI/CD support if this is something to move forward with.
