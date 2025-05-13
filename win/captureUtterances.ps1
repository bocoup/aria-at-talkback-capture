# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

# Source the common functions
. "$SCRIPT_DIR\common.ps1"

$TALKBACK_PACKAGE_NAME = "com.google.android.marvin.talkback"

# Initialize temporary utterances file
$TEMP_FILE = [System.IO.Path]::GetTempFileName()

# Flags
$VERBOSE = $false
$DISPLAY_ALL_LINES = $false

# Parse command line arguments
$args = $args | ForEach-Object {
  switch ($_) {
    "-h" { 
      Write-Host "options:"
      Write-Host "-h, --help                show brief help"
      Write-Host "-v, --verbose             show entire TalkBack output line for any given utterance"
      Write-Host "-a, --display-all-lines   show all TalkBack output lines, even if no clear utterances to be captured. `"--verbose`" will be automatically enabled"
      exit 0
    }
    "--help" { 
      Write-Host "options:"
      Write-Host "-h, --help                show brief help"
      Write-Host "-v, --verbose             show entire TalkBack output line for any given utterance"
      Write-Host "-a, --display-all-lines   show all TalkBack output lines, even if no clear utterances to be captured. `"--verbose`" will be automatically enabled"
      exit 0
    }
    "-v" { $VERBOSE = $true }
    "--verbose" { $VERBOSE = $true }
    "-a" { 
      $VERBOSE = $true
      $DISPLAY_ALL_LINES = $true 
    }
    "--display-all-lines" { 
      $VERBOSE = $true
      $DISPLAY_ALL_LINES = $true 
    }
    default { $_ }
  }
}

# Handle cleanup and display collected utterances
function Cleanup {
  Write-Host "`n`nCollected utterances:"
  if ((Get-Item $TEMP_FILE).Length -gt 0) {
    $utterances = Get-Content $TEMP_FILE
    Write-Host $utterances
    # Copy to clipboard
    Set-Clipboard -Value $utterances
    Write-Host "`nCopied to clipboard"
  }
  else {
    Write-Host "No utterances were collected."
  }
  # Clean up temp file
  Remove-Item $TEMP_FILE -Force
  exit 0
}

# Register cleanup function to run on script exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

# Register cleanup function to run on Ctrl+C
[Console]::TreatControlCAsInput = $false
$null = Register-EngineEvent -SourceIdentifier Microsoft.PowerShell.Console.CancelKeyPress -Action { Cleanup }

if (-not (Find-Adb)) {
  exit 1
}

if (-not (Check-DeveloperMode)) {
  exit 1
}

if (-not (Check-TalkbackEnabled)) {
  Write-Host "TalkBack is not enabled. You can run enableTalkback.ps1 to enable it."
  exit 1
}

Write-Host "`nUtterances will continue to be collected until the end of the example is found.`nYou can also press Ctrl+C to stop capturing and display the collected utterances`n"
Write-Host "Starting to capture TalkBack logs..."
Write-Host "Please press the 'Run Test Setup' button now..."

# Clear any existing logcat buffer
Clear-Logcat

# Start capturing logs and filter for TalkBack utterances
$pid = & $ADB_LOCATION shell pidof -s $TALKBACK_PACKAGE_NAME
if ($LASTEXITCODE -eq 0) {
  & $ADB_LOCATION logcat --pid=$pid | Select-String -Pattern "talkback|utterance" | ForEach-Object {
    $line = $_.Line
        
    # Look for ACTION_CLICK and Run Test Setup in the same line
    if ($line -match "ACTION_CLICK.*Run Test Setup") {
      Write-Host "--- Start of Example ---`n"
      $capturing = $true
            
      # Continue capturing the next utterances
      while ($capturing) {
        $next_line = & $ADB_LOCATION logcat --pid=$pid -d | Select-String -Pattern "talkback|utterance" | Select-Object -First 1
        if ($next_line) {
          $next_line = $next_line.Line
                    
          if ($DISPLAY_ALL_LINES) {
            Write-Host $next_line
          }

          # Check for "End of Example" text
          if ($next_line -match "End of Example") {
            Write-Host "`n--- End of Example ---"
            Cleanup
          }

          # Extract text from lines containing "text="
          if ($next_line -match 'text=.*utterance') {
            if ($VERBOSE -and -not $DISPLAY_ALL_LINES) {
              Write-Host $next_line
            }

            $new_utterance = if ($next_line -match 'text="([^"]*)"') {
              $matches[1]
            }
                        
            if ($new_utterance) {
              Write-Host $new_utterance
              # Join the utterances with double spaces
              "$new_utterance  " | Add-Content $TEMP_FILE
            }
          }
        }
        Start-Sleep -Milliseconds 100
      }
    }
  }
}
else {
  Write-Host "Failed to get TalkBack process ID. Please check if TalkBack is running."
  exit 1
} 