# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set execution policy to allow running local scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Function to run a script
function Run-Script {
    param (
        [string]$scriptName
    )
    
    $scriptPath = Join-Path $SCRIPT_DIR $scriptName
    if (Test-Path $scriptPath) {
        & $scriptPath
    } else {
        Write-Host "Script not found: $scriptName"
    }
}

# Get the script name from command line arguments
if ($args.Count -gt 0) {
    $scriptName = $args[0]
    Run-Script $scriptName
} else {
    Write-Host "Please specify a script to run. Available scripts:"
    Get-ChildItem -Path $SCRIPT_DIR -Filter "*.ps1" | 
        Where-Object { $_.Name -ne "run.ps1" } | 
        ForEach-Object {
            Write-Host "  $($_.Name)"
        }
}
